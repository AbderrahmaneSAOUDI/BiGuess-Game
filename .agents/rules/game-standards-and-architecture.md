---
trigger: always_on
description: Core standards, mechanics, state management, and asset architecture for BiGuess Game.
---

# BiGuess Game Standards & Architecture

## 1. Core Game Principles
- **Offline Face-to-Face Engagement**: BiGuess is an offline 2-player character deduction game. Core gameplay must run 100% offline with zero network latency.
- **Layered Clean Architecture**:
  - `lib/data/`: Data sources (asset manifest, topic loader, local preferences).
  - `lib/domain/`: Pure Dart domain models (`GameState`, `Character`, `TopicPack`, `SemVer`) and use cases.
  - `lib/presentation/`: Screens (`game`, `topics`, `packs`), widgets (`animations`, `common`), dialogs (`update`, `info`).
  - `lib/providers/`: Riverpod 2.x state management (`GameController`, `ThemeController`, `GameSettingsController`, `TopicPackProviders`).
  - `lib/services/`: Services (`VersionService`, `ShorebirdPatchService`, `OtaInstallerService`).

## 2. Asset Pipeline & Card Imagery
- All character images must be compressed WebP assets under `assets/images/<Topic>/<Pack>/`.
- Image assets must be properly registered in `assets_manifest.dart` or dynamic asset loaders.
- Maintain high visual fidelity while keeping individual card file sizes minimal (<50 KB).

## 3. OTA Updates & Shorebird Pipeline
- **Shorebird OTA**: Pure Dart and asset changes are eligible for instant OTA code push via Shorebird.
- **Split-ABI Release APK**: Any native changes (new plugins, AndroidManifest, Gradle, Kotlin/Java changes) require a full split-per-abi APK release (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- **Version File Triad**: When bumping version, always sync `pubspec.yaml`, `version.json`, and `lib/core/constants/app_constants.dart`.
