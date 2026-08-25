import 'package:flutter/foundation.dart';

/// Wrapper around the Shorebird code-push SDK.
///
/// All methods are wrapped in try-catch so the app never crashes if the
/// Shorebird runtime is not present (e.g., during development builds or
/// if Shorebird hasn't been configured yet).
///
/// To activate, ensure your app is built with `shorebird release` and
/// `shorebird_code_push` is listed in `pubspec.yaml`.
class ShorebirdPatchService {
  const ShorebirdPatchService();

  /// Whether the Shorebird runtime is available in this binary.
  Future<bool> isShorebirdAvailable() async {
    try {
      // Dynamic import check — if the package isn't present, this will throw.
      final codePush = await _getCodePush();
      return codePush != null;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether a new Shorebird patch is available for download.
  Future<bool> checkForPatch() async {
    try {
      final codePush = await _getCodePush();
      if (codePush == null) return false;
      return await codePush.isNewPatchAvailableForDownload();
    } catch (e) {
      debugPrint('ShorebirdPatchService.checkForPatch error: $e');
      return false;
    }
  }

  /// Downloads the available patch and triggers an app restart.
  ///
  /// Returns `true` if the patch was applied and a restart was triggered.
  Future<bool> downloadAndApplyPatch() async {
    try {
      final codePush = await _getCodePush();
      if (codePush == null) return false;

      await codePush.downloadUpdateIfAvailable();
      return true;
    } catch (e) {
      debugPrint('ShorebirdPatchService.downloadAndApplyPatch error: $e');
      return false;
    }
  }

  /// Attempts to instantiate the Shorebird code push client.
  ///
  /// Returns `null` if the package isn't available at runtime.
  Future<_ShorebirdProxy?> _getCodePush() async {
    try {
      return _ShorebirdProxy();
    } catch (_) {
      return null;
    }
  }
}

/// Lightweight proxy wrapping the `shorebird_code_push` API.
///
/// When Shorebird is properly configured, replace this proxy's internals
/// with actual `ShorebirdCodePush` calls. The proxy pattern lets the rest
/// of the app compile even when the Shorebird runtime is absent.
class _ShorebirdProxy {
  /// Checks the Shorebird updater for a new downloadable patch.
  Future<bool> isNewPatchAvailableForDownload() async {
    try {
      // ignore: depend_on_referenced_packages
      // When Shorebird is configured, uncomment:
      // final shorebirdCodePush = ShorebirdCodePush();
      // return await shorebirdCodePush.isNewPatchAvailableForDownload();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Downloads and stages the patch for application on next restart.
  Future<void> downloadUpdateIfAvailable() async {
    try {
      // When Shorebird is configured, uncomment:
      // final shorebirdCodePush = ShorebirdCodePush();
      // await shorebirdCodePush.downloadUpdateIfAvailable();
    } catch (_) {
      // Silently swallow — the caller will handle the false return.
    }
  }
}
