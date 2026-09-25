import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Progress data emitted during an APK download.
class DownloadProgress {
  /// Bytes received so far.
  final int received;

  /// Total expected bytes (0 when the server omits Content-Length).
  final int total;

  /// Fraction downloaded (0.0–1.0). Indeterminate when [total] == 0.
  final double fraction;

  /// Human-readable speed string, e.g. `"2.4 MB/s"`.
  final String speedText;

  /// Human-readable ETA string, e.g. `"~12s left"`.
  final String etaText;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.fraction,
    required this.speedText,
    required this.etaText,
  });
}

/// Manages full APK downloads, file integrity, cache cleanup, and
/// triggering the native Android package installer.
class OtaInstallerService {
  /// Name used for the in-flight download temp file.
  static const String _tempFileName = 'update.apk.tmp';

  /// Name of the completed APK file.
  static const String _apkFileName = 'update.apk';

  final Dio _dio;
  CancelToken? _cancelToken;

  OtaInstallerService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  // ---------------------------------------------------------------------------
  // Cache cleanup
  // ---------------------------------------------------------------------------

  /// Purges any stale `.apk` or `.apk.tmp` files from the app cache directory.
  Future<void> cleanStaleApks() async {
    try {
      final cacheDir = await getExternalCacheDirectories();
      final dirs = <Directory>[
        if (cacheDir != null) ...cacheDir,
        await getTemporaryDirectory(),
      ];

      for (final dir in dirs) {
        if (!dir.existsSync()) continue;
        final files = dir.listSync();
        for (final entity in files) {
          if (entity is File &&
              (entity.path.endsWith('.apk') ||
                  entity.path.endsWith('.apk.tmp'))) {
            try {
              await entity.delete();
            } catch (_) {
              // Best-effort cleanup — ignore individual file errors.
            }
          }
        }
      }
    } catch (_) {
      // Non-fatal — proceed even if cleanup fails.
    }
  }

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  /// Downloads the APK from [url], streaming progress via [onProgress].
  ///
  /// Writes to a `.tmp` file first and renames to `.apk` only after the
  /// download completes successfully, preventing corrupted partial installs.
  ///
  /// Returns the completed [File] handle to the APK on disk.
  Future<File> downloadApk(
    String url, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    _cancelToken = CancelToken();

    final cacheDir = await getTemporaryDirectory();
    final tmpPath = '${cacheDir.path}/$_tempFileName';
    final finalPath = '${cacheDir.path}/$_apkFileName';

    // Remove leftover files from previous attempts
    final tmpFile = File(tmpPath);
    final finalFile = File(finalPath);
    if (tmpFile.existsSync()) await tmpFile.delete();
    if (finalFile.existsSync()) await finalFile.delete();

    // Rolling speed tracker (keeps last 5 samples at ~500ms intervals)
    final speedSamples = <double>[];
    var lastSampleTime = DateTime.now();
    var lastSampleBytes = 0;

    await _dio.download(
      url,
      tmpPath,
      cancelToken: _cancelToken,
      onReceiveProgress: (received, total) {
        final now = DateTime.now();
        final elapsed = now.difference(lastSampleTime).inMilliseconds;

        // Sample speed every ~500ms
        if (elapsed >= 500) {
          final bytesInInterval = received - lastSampleBytes;
          final bytesPerSecond = bytesInInterval / (elapsed / 1000);
          speedSamples.add(bytesPerSecond);
          if (speedSamples.length > 5) speedSamples.removeAt(0);
          lastSampleTime = now;
          lastSampleBytes = received;
        }

        // Calculate rolling average speed
        final avgSpeed = speedSamples.isEmpty
            ? 0.0
            : speedSamples.reduce((a, b) => a + b) / speedSamples.length;

        // Calculate ETA
        final remaining = total > 0 ? total - received : 0;
        final etaSeconds =
            avgSpeed > 0 ? (remaining / avgSpeed).ceil() : 0;

        final fraction =
            total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;

        onProgress?.call(DownloadProgress(
          received: received,
          total: total,
          fraction: fraction,
          speedText: _formatSpeed(avgSpeed),
          etaText: etaSeconds > 0 ? '~${etaSeconds}s left' : '',
        ));
      },
    );

    // Atomic rename: tmp → final
    final completed = await File(tmpPath).rename(finalPath);
    return completed;
  }

  /// Cancels an in-flight download if one is active.
  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
    _cancelToken = null;
  }

  // ---------------------------------------------------------------------------
  // Install
  // ---------------------------------------------------------------------------

  /// Triggers the native Android package installer for the given APK [file].
  ///
  /// Uses the `open_filex` package which handles `FileProvider` content:// URIs
  /// and the `ACTION_INSTALL_PACKAGE` intent automatically.
  Future<void> installApk(File file) async {
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw Exception('Failed to launch installer: ${result.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }
}
