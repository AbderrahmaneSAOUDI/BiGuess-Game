---
trigger: always_on
description: Keep app release delivery distinct from local version synchronization.
---

# Release boundaries

Use the `biguess-ota-release` skill for a requested APK/OTA release or updater change. Read `scripts/release.py` before running its pipeline: a no-flags invocation can publish, and `--dry-run` is not a complete pipeline dry run.

- `python3 scripts/release.py --version-only` synchronizes from pubspec but also regenerates URLs and can detect native changes. For the normal commit lifecycle use `version_increment.py`, which preserves release metadata.
- Native plugins/platform changes need a new binary; set the native-change policy accordingly. Dart-only changes are patch candidates, subject to installed Shorebird compatibility and an existing base release. Asset patchability must be verified, not assumed.
- VersionService selects a full APK for newer major/minor versions; the date minor can change daily even when requesting a patch bump. Preserve mandatory/minimum-version and ABI-fallback behavior.
- Standard split builds use `flutter build apk --release --split-per-abi`. Check actual arm64-v8a, armeabi-v7a, and x86_64 artifacts, URLs, and signing before publishing metadata.
- A normal Git sync does not authorize release tags, GitHub releases, APK uploads, OTA patches, or backend deployment. Honor release authorization already given in the session; do not ask for it again.
