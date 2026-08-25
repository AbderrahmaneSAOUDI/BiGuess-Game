import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_guess_game/domain/models/remote_version.dart';
import 'package:restart_app/restart_app.dart';

import '../../domain/models/sem_ver.dart';
import '../../domain/models/update_decision.dart';
import '../../domain/models/update_state.dart';
import '../../services/ota_installer_service.dart';
import '../../services/shorebird_patch_service.dart';
import '../../services/version_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final versionServiceProvider = Provider<VersionService>((_) {
  return const VersionService();
});

final otaInstallerServiceProvider = Provider<OtaInstallerService>((_) {
  return OtaInstallerService();
});

final shorebirdPatchServiceProvider = Provider<ShorebirdPatchService>((_) {
  return ShorebirdPatchService();
});

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
  return UpdateController(
    versionService: ref.watch(versionServiceProvider),
    otaInstaller: ref.watch(otaInstallerServiceProvider),
    shorebirdPatch: ref.watch(shorebirdPatchServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Orchestrates the full update pipeline on the splash screen.
///
/// Manages the sequential state transitions:
/// `Idle → Checking → Downloading/Patching → Installing/Restarting → Completed`
///
/// All async exceptions are caught and surfaced as [UpdateError] states.
class UpdateController extends StateNotifier<UpdateState> {
  final VersionService _versionService;
  final OtaInstallerService _otaInstaller;
  final ShorebirdPatchService _shorebirdPatch;

  /// Cached local version for use in retry/error logic.
  SemVer? _localVersion;

  /// Cached min required version for skip eligibility.
  SemVer? _minRequired;

  UpdateController({
    required VersionService versionService,
    required OtaInstallerService otaInstaller,
    required ShorebirdPatchService shorebirdPatch,
  })  : _versionService = versionService,
        _otaInstaller = otaInstaller,
        _shorebirdPatch = shorebirdPatch,
        super(const UpdateIdle());

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Runs the full update check and apply pipeline.
  Future<void> runUpdateCheck() async {
    if (!mounted) return;
    state = const UpdateChecking();

    try {
      // 1. Fetch local version
      _localVersion = await _versionService.getLocalVersion();
      final local = _localVersion!;

      // 2. Fetch remote version manifest (8s timeout)
      late final RemoteVersion remoteVersion;
      try {
        remoteVersion = await _versionService.fetchRemoteVersion();
      } on TimeoutException {
        _handleNetworkFailure(local, 'Connection timed out');
        return;
      } on SocketException catch (e) {
        _handleNetworkFailure(local, 'No internet connection: ${e.message}');
        return;
      } catch (e) {
        _handleNetworkFailure(local, 'Failed to check for updates');
        return;
      }

      _minRequired = SemVer.parse(remoteVersion.minRequiredVersion);

      // 3. Query device CPU architecture & evaluate update decision
      final deviceAbis = await _versionService.getDeviceSupportedAbis();
      final decision = _versionService.evaluateUpdate(
        local,
        remoteVersion,
        deviceAbis: deviceAbis,
      );

      switch (decision) {
        case UpdateNone():
          if (!mounted) return;
          state = const UpdateCompleted();

        case UpdateFullApk():
          await _handleFullApkUpdate(decision);

        case UpdateShorebirdPatch():
          await _handleShorebirdPatch();
      }
    } catch (e) {
      debugPrint('UpdateController.runUpdateCheck unexpected error: $e');
      if (!mounted) return;
      state = UpdateError(
        message: 'An unexpected error occurred',
        canRetry: true,
        canSkip: _canSkipBasedOnVersion(),
      );
    }
  }

  /// User chose to skip a non-mandatory update.
  void skipUpdate() {
    if (!mounted) return;
    _otaInstaller.cancelDownload();
    state = const UpdateSkipped();
  }

  /// User tapped retry after an error.
  Future<void> retryUpdate() async {
    await runUpdateCheck();
  }

  // -------------------------------------------------------------------------
  // Full APK update pipeline
  // -------------------------------------------------------------------------

  Future<void> _handleFullApkUpdate(UpdateFullApk decision) async {
    if (!mounted) return;

    // Clean stale APKs before starting
    await _otaInstaller.cleanStaleApks();

    state = const UpdateDownloading(
      progress: 0,
      speedText: '',
      etaText: '',
    );

    try {
      final apkFile = await _otaInstaller.downloadApk(
        decision.apkUrl,
        onProgress: (progress) {
          if (!mounted) return;
          state = UpdateDownloading(
            progress: progress.fraction,
            speedText: progress.speedText,
            etaText: progress.etaText,
            totalBytes: progress.total,
            receivedBytes: progress.received,
          );
        },
      );

      if (!mounted) return;
      state = const UpdateInstalling();

      await _otaInstaller.installApk(apkFile);

      // The system installer takes over from here.
      // The app will be in the background. If the user comes back without
      // installing, they'll see the splash again on next launch.
    } catch (e) {
      debugPrint('APK download/install error: $e');
      if (!mounted) return;
      state = UpdateError(
        message: 'Download failed. Please try again.',
        canRetry: true,
        canSkip: !decision.mandatory,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Shorebird patch pipeline
  // -------------------------------------------------------------------------

  Future<void> _handleShorebirdPatch() async {
    if (!mounted) return;
    state = const UpdatePatching();

    try {
      final available = await _shorebirdPatch.isShorebirdAvailable();
      if (!available) {
        // Shorebird not configured — skip silently
        if (!mounted) return;
        state = const UpdateCompleted();
        return;
      }

      final hasPatch = await _shorebirdPatch.checkForPatch();
      if (!hasPatch) {
        if (!mounted) return;
        state = const UpdateCompleted();
        return;
      }

      final applied = await _shorebirdPatch.downloadAndApplyPatch();
      if (!applied) {
        if (!mounted) return;
        state = const UpdateCompleted();
        return;
      }

      // Patch applied — restart the app
      if (!mounted) return;
      state = const UpdateRestarting();

      // Brief delay so the user sees the "Restarting" status
      await Future<void>.delayed(const Duration(milliseconds: 800));

      Restart.restartApp();
    } catch (e) {
      debugPrint('Shorebird patch error: $e');
      if (!mounted) return;
      state = const UpdateError(
        message: 'Patch failed to apply',
        canRetry: true,
        canSkip: true, // Shorebird patches are never mandatory
      );
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Handles network failure based on whether the current version meets
  /// the minimum required version.
  void _handleNetworkFailure(SemVer local, String message) {
    if (!mounted) return;

    // We can't know min_required_version without a network response,
    // so we gracefully proceed if we have no cached value.
    final canSkip = _canSkipBasedOnVersion();

    if (canSkip) {
      // Version is acceptable — proceed to the game
      state = const UpdateCompleted();
    } else {
      state = UpdateError(
        message: message,
        canRetry: true,
        canSkip: false,
      );
    }
  }

  /// Whether the user can skip based on version checks.
  ///
  /// If we don't have min_required info (network never succeeded), we
  /// default to allowing skip to avoid trapping users.
  bool _canSkipBasedOnVersion() {
    if (_localVersion == null || _minRequired == null) return true;
    return _localVersion! >= _minRequired!;
  }
}
