/// The outcome of comparing local vs remote versions.
///
/// Determines which update path (if any) the app should follow.
sealed class UpdateDecision {
  const UpdateDecision();
}

/// No update is needed — the app is up to date.
class UpdateNone extends UpdateDecision {
  const UpdateNone();
}

/// A full APK download and install is required.
///
/// Triggered when major/minor version changes or native code has changed.
class UpdateFullApk extends UpdateDecision {
  /// If `true`, the user cannot skip this update (version < minRequired).
  final bool mandatory;

  /// Direct download URL for the APK binary.
  final String apkUrl;

  /// Human-readable release notes for the update.
  final String releaseNotes;

  const UpdateFullApk({
    required this.mandatory,
    required this.apkUrl,
    required this.releaseNotes,
  });
}

/// A Shorebird code-push patch is available.
///
/// Triggered when only the patch version has incremented and no native
/// changes are present.
class UpdateShorebirdPatch extends UpdateDecision {
  const UpdateShorebirdPatch();
}
