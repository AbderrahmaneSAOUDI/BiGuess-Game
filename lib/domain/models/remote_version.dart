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
  final String? sha256;
  final Map<String, String> sha256Hashes;

  const RemoteVersion({
    required this.latestVersion,
    required this.buildNumber,
    required this.minRequiredVersion,
    required this.hasNativeChanges,
    required this.apkUrl,
    this.apkUrls = const {},
    required this.releaseNotes,
    this.sha256,
    this.sha256Hashes = const {},
  });

  factory RemoteVersion.fromJson(Map<String, dynamic> json) {
    final rawApkUrls = json['apk_urls'];
    final Map<String, String> parsedUrls = {};

    if (rawApkUrls is Map) {
      for (final entry in rawApkUrls.entries) {
        if (entry.key != null && entry.value != null) {
          parsedUrls[entry.key.toString().toLowerCase()] = entry.value
              .toString();
        }
      }
    }

    final defaultApkUrl = json['apk_url'] as String? ?? '';
    final rawBuild = json['build_number'];
    final buildNumber = rawBuild is int
        ? rawBuild
        : int.tryParse(rawBuild?.toString() ?? '') ?? 0;

    final rawNative = json['has_native_changes'];
    final hasNativeChanges = rawNative is bool
        ? rawNative
        : (rawNative?.toString().toLowerCase() == 'true');

    final rawShaHashes = json['sha256_hashes'] ?? json['apk_hashes'];
    final Map<String, String> parsedHashes = {};
    if (rawShaHashes is Map) {
      for (final entry in rawShaHashes.entries) {
        if (entry.key != null && entry.value != null) {
          parsedHashes[entry.key.toString().toLowerCase()] = entry.value
              .toString();
        }
      }
    }
    final defaultSha256 =
        json['sha256'] as String? ?? (json['apk_sha256'] as String?);

    return RemoteVersion(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      buildNumber: buildNumber,
      minRequiredVersion: json['min_required_version'] as String? ?? '0.0.0',
      hasNativeChanges: hasNativeChanges,
      apkUrl: defaultApkUrl,
      apkUrls: parsedUrls,
      releaseNotes: json['release_notes'] as String? ?? '',
      sha256: defaultSha256,
      sha256Hashes: parsedHashes,
    );
  }

  /// Resolves the expected SHA-256 hash for the device's CPU architecture.
  String? resolveSha256(List<String> deviceAbis) {
    if (sha256Hashes.isNotEmpty) {
      for (final abi in deviceAbis) {
        final cleanAbi = abi.trim().toLowerCase();
        if (sha256Hashes.containsKey(cleanAbi) &&
            sha256Hashes[cleanAbi]!.isNotEmpty) {
          return sha256Hashes[cleanAbi];
        }
      }
      if (sha256Hashes.containsKey('universal') &&
          sha256Hashes['universal']!.isNotEmpty) {
        return sha256Hashes['universal'];
      }
    }
    return sha256;
  }

  /// Resolves the most specific APK download URL for the device's CPU architecture.
  ///
  /// Traverses [deviceAbis] in priority order (e.g. `['arm64-v8a', 'armeabi-v7a']`).
  /// If a match is found in [apkUrls], returns it; otherwise falls back to
  /// [apkUrl] or the default 64-bit ARM APK.
  String resolveApkUrl(List<String> deviceAbis) {
    if (apkUrls.isNotEmpty) {
      for (final abi in deviceAbis) {
        final cleanAbi = abi.trim().toLowerCase();
        if (apkUrls.containsKey(cleanAbi) && apkUrls[cleanAbi]!.isNotEmpty) {
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
        : 'https://github.com/AbderrahmaneSAOUDI/BiGuess/releases/latest/download/app-arm64-v8a-release.apk';
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'build_number': buildNumber,
    'min_required_version': minRequiredVersion,
    'has_native_changes': hasNativeChanges,
    if (apkUrls.isNotEmpty) 'apk_urls': apkUrls,
    'apk_url': apkUrl,
    if (sha256 != null && sha256!.isNotEmpty) 'sha256': sha256,
    if (sha256Hashes.isNotEmpty) 'sha256_hashes': sha256Hashes,
    'release_notes': releaseNotes,
  };

  @override
  String toString() =>
      'RemoteVersion(v$latestVersion+$buildNumber, native=$hasNativeChanges, abis=${apkUrls.keys.toList()})';
}
