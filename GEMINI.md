# BiGuess Game — GEMINI.md

## Project Overview
`BiGuess` is an offline, face-to-face 2-player character deduction party game developed in Flutter and Dart. Designed for anime conventions, gatherings, and casual hangouts, players interrogate each other with rapid-fire Yes/No questions to deduce mystery cards from 18+ franchises and over 920 curated character cards.

## Tech Stack
- **Framework:** Flutter (Channel stable, ≥3.0.0 <4.0.0).
- **Language:** Dart 3.x (sound null safety, pattern matching, switch expressions).
- **State Management:** Flutter Riverpod 2.6.x (`flutter_riverpod`, `riverpod`).
- **UI Design System:** Material 3 with custom dynamic theming per topic/pack (`AppTheme`, `AppConstants`).
- **OTA Delivery:** Shorebird Code Push 2.0 (`shorebird_code_push`) for instant hot patches + in-app split-ABI APK installer (`dio`, `open_filex`, `restart_app`).
- **Fonts & Imagery:** Self-hosted Google Sans typography (`assets/fonts/`), optimized WebP character cards (`assets/images/`).

## Architecture & Structure
- **Data Layer (`lib/data/`):** Asset manifest loading and topic-pack data resolution (`TopicPackDataSource`).
- **Domain Layer (`lib/domain/`):** Pure Dart models (`Character`, `GameState`, `SemVer`, `RemoteVersion`, `TopicPack`) and business logic use cases (`SelectCharacterUseCase`).
- **Presentation Layer (`lib/presentation/`):**
  - Screens: `TopicsScreen` (topic grid), `PacksScreen` (franchise pack selection), `GameScreen` (active 2-player duel).
  - Widgets: `AnimatedCharacterCard` (3D flip & interactive scaling), `AnimatedCountdown`, `ActionButton`.
  - Dialogs: `UpdateDialog` (mandatory & optional OTA updater), `GameInfoDialog` (rules & how to play).
- **State Providers (`lib/providers/`):**
  - `GameController`: Duel timer, card shuffling, secret character assignment, and turn states.
  - `ThemeController`: Dynamic Material 3 theme switching.
  - `GameSettingsController`: Round duration, timer mode, and card count settings.
  - `TopicPackProviders`: Topic pack loading and filtering.
- **Services (`lib/services/`):**
  - `VersionService`: Local vs remote SemVer resolution and update strategy evaluation.
  - `ShorebirdPatchService`: Shorebird engine listener and background patch downloader.
  - `OtaInstallerService`: Download progress streaming and native package installer intent triggers.

## Key Commands
- `flutter test` — Run complete test suite (unit and widget tests).
- `flutter analyze` — Run static analyzer on all Dart source files.
- `flutter run` — Launch development build on connected target.
- `flutter build apk --release --split-per-abi` — Compile optimized split-ABI release APKs.
- `python3 scripts/release.py --version-only` — Verify and synchronize version triad.
- `python3 .agents/hooks/git_auto_commit_push.py` — Automated version increment, commit, and push.

## Conventions & Rules
- **Pure Offline Gameplay:** Core game loops must never fail or block due to lack of internet connectivity.
- **Widget Performance:** Always prefer `const` constructors. Extract subtrees into standalone `StatelessWidget` classes to enable element caching.
- **State & Lifecycle Guards:** Guard async UI interactions with `if (!mounted) return;`. Properly dispose controllers and animation listeners.
- **Strict Scope Fidelity:** Never add unprompted elements, features, or copy without explicit user request or prior approval.
- **Silent Date-Based Versioning:**
  - Inception date: `2025-05-27` (`BASE_DATE`).
  - Calculate minor version as elapsed days since `2025-05-27`: `floor((Current Date - 2025-05-27) in days)`.
  - Increment patch version silently at every substantive commit.
  - Synchronize the Version File Triad: `pubspec.yaml`, `version.json`, and `lib/core/constants/app_constants.dart`.
