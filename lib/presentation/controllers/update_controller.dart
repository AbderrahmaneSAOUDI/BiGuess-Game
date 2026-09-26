import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restart_app/restart_app.dart';

import '../../domain/models/remote_version.dart';
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

/// Orchestrates the update pipeline across the app.
///
/// Supports silent background checking on launch and interactive manual checks
/// from the About/Settings tab.
class UpdateController extends StateNotifier<UpdateState> {
  final VersionService _versionService;
  final OtaInstallerService _otaInstaller;
  final ShorebirdPatchService _shorebirdPatch;

  SemVer? _localVersion;
  SemVer? _minRequired;
  RemoteVersion? _remoteVersion;

  UpdateController({
    required VersionService versionService,
    required OtaInstallerService otaInstaller,
    required ShorebirdPatchService shorebirdPatch,
  })  : _versionService = versionService,
        _otaInstaller = otaInstaller,
        _shorebirdPatch = shorebirdPatch,
        super(const UpdateIdle());

  SemVer? get localVersion => _localVersion;
  SemVer? get minRequired => _minRequired;
  RemoteVersion? get remoteVersion => _remoteVersion;

  // -------------------------------------------------------------------------
  // Check for updates
  // -------------------------------------------------------------------------

  /// Runs the update check.
  ///
  /// If [silent] is true, network failures or up-to-date states will complete
  /// silently without surfacing errors to avoid interrupting gameplay.
  Future<void> checkForUpdates({bool silent = false}) async {
    if (!mounted) return;
    state = const UpdateChecking();

    try {
      // 1. Resolve local installed version
      _localVersion = await _versionService.getLocalVersion();
      final local = _localVersion!;

      // 2. First check if a Shorebird patch is ready
      final isSbAvailable = await _shorebirdPatch.isShorebirdAvailable();
      if (isSbAvailable) {
        final hasPatch = await _shorebirdPatch.checkForPatch();
        if (hasPatch) {
          if (silent) {
            // Apply patch silently in the background
            await _shorebirdPatch.downloadAndApplyPatch();
            if (!mounted) return;
            state = const UpdateCompleted('New patch installed. Restart anytime to apply.');
            return;
          } else {
            if (!mounted) return;
            state = UpdateAvailable(
              decision: const UpdateShorebirdPatch(),
              currentVersion: local.toString(),
              latestVersion: local.toString(),
              releaseNotes: 'Over-the-air code patch available with instant bug fixes and improvements.',
            );
            return;
          }
        }
      }

      // 3. Fetch remote version manifest from GitHub (8s timeout)
      late final RemoteVersion remote;
      try {
        remote = await _versionService.fetchRemoteVersion();
        _remoteVersion = remote;
      } on TimeoutException {
        if (!silent && mounted) {
          state = const UpdateError(
            message: 'Connection timed out while checking for updates.',
          );
        } else if (mounted) {
          state = const UpdateCompleted();
        }
        return;
      } on SocketException {
        if (!silent && mounted) {
          state = const UpdateError(
            message: 'No internet connection to check for updates.',
          );
        } else if (mounted) {
          state = const UpdateCompleted();
        }
        return;
      } catch (e) {
        if (!silent && mounted) {
          state = UpdateError(
            message: 'Failed to check for updates: $e',
          );
        } else if (mounted) {
          state = const UpdateCompleted();
        }
        return;
      }

      _minRequired = SemVer.parse(remote.minRequiredVersion);

      // 4. Query device CPU architecture & evaluate update decision
      final deviceAbis = await _versionService.getDeviceSupportedAbis();
      final decision = _versionService.evaluateUpdate(
        local,
        remote,
        deviceAbis: deviceAbis,
      );

      if (!mounted) return;

      switch (decision) {
        case UpdateNone():
          state = UpdateCompleted(
            silent ? '' : 'You are running the latest version (v${local.toString()})',
          );

        case UpdateFullApk():
          state = UpdateAvailable(
            decision: decision,
            currentVersion: local.toString(),
            latestVersion: remote.latestVersion,
            releaseNotes: decision.releaseNotes.isNotEmpty
                ? decision.releaseNotes
                : 'New version v${remote.latestVersion} available.',
          );

        case UpdateShorebirdPatch():
          if (silent) {
            // Silently download and apply the patch
            final applied = await _shorebirdPatch.downloadAndApplyPatch();
            if (applied && mounted) {
              state = const UpdateCompleted('Patch downloaded. Restart anytime.');
            } else if (mounted) {
              state = const UpdateCompleted();
            }
          } else {
            state = UpdateAvailable(
              decision: decision,
              currentVersion: local.toString(),
              latestVersion: remote.latestVersion,
              releaseNotes: remote.releaseNotes.isNotEmpty
                  ? remote.releaseNotes
                  : 'Fast OTA patch available.',
            );
          }
      }
    } catch (e) {
      debugPrint('UpdateController.checkForUpdates error: $e');
      if (!mounted) return;
      if (silent) {
        state = const UpdateCompleted();
      } else {
        state = const UpdateError(
          message: 'An unexpected error occurred during version check.',
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Full APK download & installation
  // -------------------------------------------------------------------------

  Future<void> downloadAndInstallApk(UpdateFullApk decision) async {
    if (!mounted) return;

    // Clean stale APKs first
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
    } catch (e) {
      debugPrint('APK download/install error: $e');
      if (!mounted) return;
      state = UpdateError(
        message: 'Download or installation failed. Please try again.',
        canRetry: true,
        canSkip: !decision.mandatory,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Shorebird patch execution
  // -------------------------------------------------------------------------

  Future<void> applyShorebirdPatch() async {
    if (!mounted) return;
    state = const UpdatePatching();

    try {
      final applied = await _shorebirdPatch.downloadAndApplyPatch();
      if (!applied) {
        if (!mounted) return;
        state = const UpdateError(
          message: 'Failed to download patch. Please try again.',
        );
        return;
      }

      if (!mounted) return;
      state = const UpdateRestarting();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      Restart.restartApp();
    } catch (e) {
      debugPrint('Shorebird patch apply error: $e');
      if (!mounted) return;
      state = const UpdateError(
        message: 'Failed to apply patch.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // User actions
  // -------------------------------------------------------------------------

  void skipUpdate() {
    if (!mounted) return;
    _otaInstaller.cancelDownload();
    state = const UpdateSkipped();
  }

  void resetToIdle() {
    if (!mounted) return;
    state = const UpdateIdle();
  }
}
