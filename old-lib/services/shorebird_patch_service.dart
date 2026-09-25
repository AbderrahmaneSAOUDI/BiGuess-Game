import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Wrapper around the Shorebird code-push SDK (`ShorebirdUpdater`).
///
/// All methods are wrapped in try-catch so the app never crashes if the
/// Shorebird runtime is not present (e.g., during local development builds or
/// if Shorebird hasn't been configured yet).
///
/// To activate:
/// 1. Run `shorebird init` to generate `shorebird.yaml`.
/// 2. Build release with `shorebird release android`.
/// 3. Push patches with `shorebird patch android`.
class ShorebirdPatchService {
  final ShorebirdUpdater _updater;

  ShorebirdPatchService({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  /// Whether the Shorebird runtime is available in this binary.
  Future<bool> isShorebirdAvailable() async {
    try {
      return _updater.isAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether a new Shorebird patch is available for download.
  Future<bool> checkForPatch() async {
    try {
      if (!_updater.isAvailable) return false;
      final status = await _updater.checkForUpdate();
      return status == UpdateStatus.outdated ||
          status == UpdateStatus.restartRequired;
    } catch (e) {
      debugPrint('ShorebirdPatchService.checkForPatch error: $e');
      return false;
    }
  }

  /// Downloads the available patch.
  ///
  /// Returns `true` if the patch was successfully downloaded and staged.
  Future<bool> downloadAndApplyPatch() async {
    try {
      if (!_updater.isAvailable) return false;
      await _updater.update();
      return true;
    } catch (e) {
      debugPrint('ShorebirdPatchService.downloadAndApplyPatch error: $e');
      return false;
    }
  }
}
