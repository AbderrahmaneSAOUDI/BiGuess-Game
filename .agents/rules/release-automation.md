# Version & Release Automation Rules

## Version File Triad

Three files must always stay in sync when the app version changes:

1. **`pubspec.yaml`** — `version:` field (source of truth)
2. **`version.json`** — remote update manifest served to the OTA updater
3. **`lib/core/constants/app_constants.dart`** — `defaultVersion` string displayed on splash

### When the user changes `pubspec.yaml` version:

1. Run `python3 scripts/release.py --version-only` to auto-sync `version.json` and `app_constants.dart`
2. If the version change involves native code (new plugin, AndroidManifest change, Kotlin/Swift change), run with `--native` flag
3. Report what was synced

### When the user asks to "bump version" or "release":

1. Use `./scripts/run.sh release` or `python3 scripts/release.py` with appropriate flags
2. Ask which bump type (major/minor/patch) if not specified
3. Ask for release notes if not provided
4. The script handles: version bump → version.json sync → app_constants sync → APK build → git commit/tag/push → GitHub release

## Version Semantics

- **Major/Minor bump** or adding native dependencies → triggers full APK update path for users
- **Patch bump** with no native changes → triggers Shorebird code-push path for users
- Set `has_native_changes: true` whenever: a new Flutter plugin is added, `AndroidManifest.xml` changes, `build.gradle.kts` changes, or any Kotlin/Swift code changes

## Split-ABI Architecture

- **Default Build Mode:** `flutter build apk --release --split-per-abi` generates 3 optimized APKs:
  - `app-arm64-v8a-release.apk` (64-bit ARM ~95% of devices)
  - `app-armeabi-v7a-release.apk` (32-bit ARM legacy)
  - `app-x86_64-release.apk` (emulators & chromebooks)
- **Target Resolution:** Device queries `DeviceInfoPlugin().androidInfo.supportedAbis` on splash and downloads only the matching ~18MB slice instead of the 35MB+ fat APK.
- **Universal Fallback:** `apk_urls.universal` or `apk_url` provides graceful fallback if ABI is not recognized.

## CLI Quick Reference

```bash
# Interactive Prompt Mode (Recommended for manual terminal use)
./scripts/run.sh release    # Step-by-step interactive prompts: bump type, native changes, notes, draft
./scripts/run.sh version    # Step-by-step interactive prompts: bump, sync, view
./scripts/run.sh build      # Interactive build target selector
./scripts/run.sh            # Main interactive developer menu (options [1]-[9])

# Non-interactive / Agent Automation Flags
./scripts/run.sh version --bump patch
./scripts/run.sh release --bump minor --notes "New anime pack added"
./scripts/run.sh release --bump minor --native --notes "Added new plugin"
./scripts/run.sh release --skip-build --notes "Bug fixes"
```

## Never Do

- Never edit `version.json` manually — always use the scripts to generate it from `pubspec.yaml`
- Never push code with `version.json` out of sync with `pubspec.yaml`
- Never forget `--native` when native code has changed — this controls whether users get a full APK download or a lightweight Shorebird patch
