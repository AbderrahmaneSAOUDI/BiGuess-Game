/// State machine for the splash screen update pipeline.
///
/// Drives the progress bar, status text, and user interaction on the splash.
sealed class UpdateState {
  const UpdateState();
}

/// Initial state — no update activity yet.
class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

/// Fetching remote `version.json` and comparing versions.
class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

/// Streaming APK download in progress.
class UpdateDownloading extends UpdateState {
  /// Fraction downloaded (0.0 – 1.0).
  final double progress;

  /// Human-readable speed string, e.g. `"2.4 MB/s"`.
  final String speedText;

  /// Human-readable ETA string, e.g. `"~12s left"`.
  final String etaText;

  /// Total download size in bytes (0 if unknown).
  final int totalBytes;

  /// Bytes received so far.
  final int receivedBytes;

  const UpdateDownloading({
    required this.progress,
    required this.speedText,
    required this.etaText,
    this.totalBytes = 0,
    this.receivedBytes = 0,
  });
}

/// APK download complete — launching the system package installer.
class UpdateInstalling extends UpdateState {
  const UpdateInstalling();
}

/// Shorebird patch is being downloaded and applied.
class UpdatePatching extends UpdateState {
  const UpdatePatching();
}

/// Shorebird patch complete — app is about to restart.
class UpdateRestarting extends UpdateState {
  const UpdateRestarting();
}

/// Update flow finished successfully (or no update was needed).
class UpdateCompleted extends UpdateState {
  const UpdateCompleted();
}

/// User chose to skip a non-mandatory update.
class UpdateSkipped extends UpdateState {
  const UpdateSkipped();
}

/// An error occurred during the update pipeline.
class UpdateError extends UpdateState {
  /// User-facing error description.
  final String message;

  /// Whether the user can retry the failed operation.
  final bool canRetry;

  /// Whether the user can skip past the error (false for mandatory updates).
  final bool canSkip;

  const UpdateError({
    required this.message,
    this.canRetry = true,
    this.canSkip = true,
  });
}
