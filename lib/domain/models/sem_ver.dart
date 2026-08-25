/// Lightweight semantic versioning value object.
///
/// Parses version strings in the format `major.minor.patch+build` and provides
/// comparison operators and helper methods for update decision logic.
class SemVer implements Comparable<SemVer> {
  final int major;
  final int minor;
  final int patch;
  final int buildNumber;

  const SemVer({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber = 0,
  });

  /// Parses a version string like `"1.2.3+15"` or `"1.2.3"` into a [SemVer].
  ///
  /// Strips any leading `v` or `V` prefix. Returns `0.0.0+0` on failure.
  factory SemVer.parse(String version, [int? explicitBuildNumber]) {
    try {
      final cleaned = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
      int build = explicitBuildNumber ?? 0;
      String versionPart = cleaned;

      if (cleaned.contains('+')) {
        final split = cleaned.split('+');
        versionPart = split[0];
        if (explicitBuildNumber == null && split.length > 1) {
          build = int.tryParse(split[1]) ?? 0;
        }
      }

      final parts = versionPart.split('.');

      return SemVer(
        major: parts.isNotEmpty ? int.parse(parts[0]) : 0,
        minor: parts.length > 1 ? int.parse(parts[1]) : 0,
        patch: parts.length > 2 ? int.parse(parts[2]) : 0,
        buildNumber: build,
      );
    } catch (_) {
      return const SemVer(major: 0, minor: 0, patch: 0, buildNumber: 0);
    }
  }

  /// Zero / unknown version sentinel.
  static const SemVer zero = SemVer(major: 0, minor: 0, patch: 0, buildNumber: 0);

  /// Whether [other] has a higher major or minor component than `this`.
  ///
  /// This signals a binary-breaking change requiring a full APK update.
  bool isNewerMajorOrMinorThan(SemVer other) {
    if (major > other.major) return true;
    if (major == other.major && minor > other.minor) return true;
    return false;
  }

  /// Whether [other] has a higher patch component or build number with matching major+minor.
  ///
  /// This signals a Dart-only change eligible for a Shorebird patch.
  bool isNewerPatchThan(SemVer other) {
    if (major == other.major && minor == other.minor) {
      if (patch > other.patch) return true;
      if (patch == other.patch && buildNumber > other.buildNumber) return true;
    }
    return false;
  }

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return buildNumber.compareTo(other.buildNumber);
  }

  bool operator <(SemVer other) => compareTo(other) < 0;
  bool operator >(SemVer other) => compareTo(other) > 0;
  bool operator <=(SemVer other) => compareTo(other) <= 0;
  bool operator >=(SemVer other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemVer &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          buildNumber == other.buildNumber;

  @override
  int get hashCode => Object.hash(major, minor, patch, buildNumber);

  @override
  String toString() => buildNumber > 0 ? '$major.$minor.$patch+$buildNumber' : '$major.$minor.$patch';
}
