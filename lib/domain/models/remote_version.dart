/// Represents the remote version manifest fetched from the update server.
///
/// Maps directly to the `version.json` payload structure, supporting
/// both single APK URLs and Split-ABI targeted APK URL mappings.
class RemoteVersion {
  final String latestVersion;
  final int buildNumber;
  final String minRequiredVersion;
  final bool hasNativeChanges;
  final String apkUrl;
  final Map<String, String> apkUrls;
  final String releaseNotes;

  const RemoteVersion({
    required this.latestVersion,
    required this.buildNumber,
    required this.minRequiredVersion,
    required this.hasNativeChanges,
    required this.apkUrl,
    this.apkUrls = const {},
    required this.releaseNotes,
  });

  factory RemoteVersion.fromJson(Map<String, dynamic> json) {
    final rawApkUrls = json['apk_urls'];
    final Map<String, String> parsedUrls = {};

    if (rawApkUrls is Map) {
      for (final entry in rawApkUrls.entries) {
        if (entry.key != null && entry.value != null) {
          parsedUrls[entry.key.toString().toLowerCase()] =
              entry.value.toString();
        }
      }
    }

    final defaultApkUrl = json['apk_url'] as String? ?? '';

    return RemoteVersion(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      buildNumber: json['build_number'] as int? ?? 0,
      minRequiredVersion: json['min_required_version'] as String? ?? '0.0.0',
      hasNativeChanges: json['has_native_changes'] as bool? ?? false,
      apkUrl: defaultApkUrl,
      apkUrls: parsedUrls,
      releaseNotes: json['release_notes'] as String? ?? '',
    );
  }

  /// Resolves the most specific APK download URL for the device's CPU architecture.
  ///
  /// Traverses [deviceAbis] in priority order (e.g. `['arm64-v8a', 'armeabi-v7a']`).
  /// If a match is found in [apkUrls], returns it; otherwise falls back to
  /// `apkUrls['universal']` or [apkUrl].
  String resolveApkUrl(List<String> deviceAbis) {
    if (apkUrls.isNotEmpty) {
      for (final abi in deviceAbis) {
        final cleanAbi = abi.trim().toLowerCase();
        if (apkUrls.containsKey(cleanAbi) &&
            apkUrls[cleanAbi]!.isNotEmpty) {
          return apkUrls[cleanAbi]!;
        }
      }
      if (apkUrls.containsKey('universal') &&
          apkUrls['universal']!.isNotEmpty) {
        return apkUrls['universal']!;
      }
    }
    return apkUrl.isNotEmpty
        ? apkUrl
        : 'https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/releases/latest/download/app-release.apk';
  }

  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'build_number': buildNumber,
        'min_required_version': minRequiredVersion,
        'has_native_changes': hasNativeChanges,
        if (apkUrls.isNotEmpty) 'apk_urls': apkUrls,
        'apk_url': apkUrl,
        'release_notes': releaseNotes,
      };

  @override
  String toString() =>
      'RemoteVersion(v$latestVersion+$buildNumber, native=$hasNativeChanges, abis=${apkUrls.keys.toList()})';
}
