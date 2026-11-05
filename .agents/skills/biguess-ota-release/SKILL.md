---
name: biguess-ota-release
description: Hybrid OTA update and release pipeline for BiGuess Game. Explains how to trigger Shorebird patches, build split-ABI APKs, sync the version triad, and update version.json.
---

# BiGuess OTA Update & Release Runbook

BiGuess utilizes a hybrid continuous delivery engine:
1. **Shorebird Code Push**: Instant over-the-air hot patches for pure Dart & asset changes.
2. **In-App ABI-Split APK Installer**: Direct downloads of architecture-specific APK slices for updates containing native changes or major/minor bumps.

## 1. Version File Triad
When changing version numbers, always maintain synchronization across:
- `pubspec.yaml`: `version: 1.<minor>.<patch>+<build>`
- `version.json`: `latest_version`, `build_number`, `apk_urls`
- `lib/core/constants/app_constants.dart`: `defaultVersion`

## 2. Choosing Release Path
- **Pure Patch (No Native Changes)**:
  - Suitable for gameplay tweaks, bug fixes, UI adjustments, and card packs.
  - Deployed via Shorebird:
    ```bash
    shorebird patch android
    ```
- **Native Platform Release (Split-ABI APKs)**:
  - Required if `android/` configuration, Kotlin code, or native plugins change.
  - Built via:
    ```bash
    flutter build apk --release --split-per-abi
    ```
  - Resulting artifacts in `build/app/outputs/flutter-apk/`:
    - `app-arm64-v8a-release.apk`
    - `app-armeabi-v7a-release.apk`
    - `app-x86_64-release.apk`

## 3. Automation Tooling
Use `scripts/release.py`:
```bash
python3 scripts/release.py --version-only
```
Or interactively:
```bash
./scripts/run.sh release
```
