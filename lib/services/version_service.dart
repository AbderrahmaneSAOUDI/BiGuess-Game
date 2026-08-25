import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/models/remote_version.dart';
import '../domain/models/sem_ver.dart';
import '../domain/models/update_decision.dart';

/// Handles remote version fetching, local version resolution, device ABI detection,
/// and update decision evaluation based on the semantic versioning hierarchy.
class VersionService {
  /// Remote URL serving the `version.json` manifest.
  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/AbderrahmaneSAOUDI/BiGuess-Game/main/version.json';

  /// Network timeout for the version check request.
  static const Duration _timeout = Duration(seconds: 8);

  const VersionService();

  // ---------------------------------------------------------------------------
  // Remote version
  // ---------------------------------------------------------------------------

  /// Fetches and parses the remote `version.json` payload.
  ///
  /// Throws [SocketException] or [HttpException] on network failure, and
  /// [TimeoutException] if the request exceeds [_timeout].
  Future<RemoteVersion> fetchRemoteVersion() async {
    final client = HttpClient();
    try {
      client.connectionTimeout = _timeout;
      final request = await client.getUrl(Uri.parse(_versionJsonUrl));
      final response =
          await request.close().timeout(_timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Failed to fetch version.json (HTTP ${response.statusCode})',
        );
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return RemoteVersion.fromJson(json);
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Local version & Device ABIs
  // ---------------------------------------------------------------------------

  /// Reads the locally installed app version via `package_info_plus` and
  /// parses it into a [SemVer] including build number.
  Future<SemVer> getLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final buildNum = int.tryParse(info.buildNumber) ?? 0;
      return SemVer.parse(info.version, buildNum);
    } catch (_) {
      return SemVer.zero;
    }
  }

  /// Queries the Android device for its supported CPU architectures (ABIs)
  /// in priority order (e.g. `['arm64-v8a', 'armeabi-v7a', 'armeabi']`).
  Future<List<String>> getDeviceSupportedAbis() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.supportedAbis;
      }
    } catch (_) {
      // Fall back gracefully if device info cannot be retrieved
    }
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Decision engine
  // ---------------------------------------------------------------------------

  /// Applies the strict update hierarchy and resolves the targeted APK for
  /// the device's CPU architecture:
  ///
  /// 1. **Up to date** — if `local >= remoteSemVer`, returns [UpdateNone].
  /// 2. **Full APK** — if remote is newer AND (major/minor bump or `hasNativeChanges`).
  ///    Mandatory when local < `minRequiredVersion`. Resolves ABI-specific APK.
  /// 3. **Shorebird patch** — if remote patch > local patch with same
  ///    major.minor and no native changes.
  UpdateDecision evaluateUpdate(
    SemVer local,
    RemoteVersion remote, {
    List<String> deviceAbis = const [],
  }) {
    final remoteSemVer = SemVer.parse(remote.latestVersion, remote.buildNumber);
    final minRequired = SemVer.parse(remote.minRequiredVersion);

    // 1. If local version is already equal to or newer than remote, no update is needed!
    if (local >= remoteSemVer) {
      return const UpdateNone();
    }

    // 2. Full APK path:
    // Required if remote has a newer major/minor, or if native code changed.
    final needsFullApk = remoteSemVer.isNewerMajorOrMinorThan(local) ||
        remote.hasNativeChanges;

    if (needsFullApk) {
      final isMandatory = local < minRequired;
      final targetApkUrl = remote.resolveApkUrl(deviceAbis);

      return UpdateFullApk(
        mandatory: isMandatory,
        apkUrl: targetApkUrl,
        releaseNotes: remote.releaseNotes,
      );
    }

    // 3. Shorebird patch path:
    // If remote is a newer patch with NO native changes.
    if (remoteSemVer.isNewerPatchThan(local) && !remote.hasNativeChanges) {
      return const UpdateShorebirdPatch();
    }

    // 4. Otherwise up to date
    return const UpdateNone();
  }
}
