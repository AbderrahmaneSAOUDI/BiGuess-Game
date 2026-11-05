# BiGuess Game — Agent Operational Guide

BiGuess is an offline 2-player face-to-face anime & pop-culture character guessing game built with Flutter, Dart, Riverpod 2.x, Material 3, and Shorebird hybrid OTA delivery.

## Directory Map

- `lib/data/` — Data sources (`TopicPackDataSource`, asset manifest readers).
- `lib/domain/` — Core business models (`Character`, `GameState`, `SemVer`, `RemoteVersion`, `TopicPack`) and use cases (`SelectCharacterUseCase`).
- `lib/presentation/` — Presentation layer: screens (`GameScreen`, `TopicsScreen`, `PacksScreen`), widgets (`AnimatedCharacterCard`, `Countdown`, `ActionButton`), and dialogs (`UpdateDialog`, `GameInfoDialog`).
- `lib/providers/` — Riverpod 2.x state controllers (`GameController`, `ThemeController`, `GameSettingsController`, `TopicPackProviders`).
- `lib/services/` — Platform services (`VersionService`, `ShorebirdPatchService`, `OtaInstallerService`).
- `lib/core/` — Constants (`AppConstants`), theme definitions (`AppTheme`), and utilities (`AssetLoader`, `UrlHelper`).
- `assets/` — High-efficiency WebP character cards (`assets/images/`), Google Sans typography (`assets/fonts/`), and brand logos (`assets/logos/`).
- `scripts/` — Developer automation & release pipeline (`release.py`, `run.sh`).
- `test/` — Unit and widget verification suites (`test/unit/`, `test/widget/`).
- `.agents/rules/` — Persistent operational rules (architecture, versioning, quality, speed).
- `.agents/hooks/` & `hooks.json` — Lifecycle hooks (dangerous command guard, session start context, version automation).
- `.agents/sidecars/` — Background daemons (codebase indexer, test watcher) and architecture maps.
- `.agents/skills/` — On-demand procedural playbooks and workflows.

## Key Commands

- `flutter test` — Run complete unit and widget test suite.
- `flutter analyze` — Static analysis and lint verification.
- `flutter run` — Start development build on emulator or connected device.
- `flutter build apk --release --split-per-abi` — Build optimized split-ABI release APKs.
- `python3 scripts/release.py --version-only` — Synchronize version triad.
- `python3 .agents/hooks/git_auto_commit_push.py "<summary>"` — Bump version, stage, commit, and push.

## Hard Constraints & Invariants

- **Offline-First Gameplay:** Core 2-player character deduction must function 100% offline with zero runtime network latency.
- **Widget Performance & Const:** Use `const` constructors wherever possible. Extract complex UI subtrees into dedicated `StatelessWidget` classes rather than large private `_build*()` methods.
- **State & Lifecycle Safety:** Always guard with `if (!mounted) return;` after async `await` calls before calling `setState()` or interacting with `BuildContext`.
- **Resource Disposal:** Explicitly dispose all `TextEditingController`, `AnimationController`, `ScrollController`, and `FocusNode` instances in `dispose()`.
- **Zero Unprompted Additions:** Only implement changes, features, or copy explicitly requested by the user. Ask before adding or improving.
- **Version File Triad Synchronization:** When bumping the version, always ensure `pubspec.yaml`, `version.json`, and `lib/core/constants/app_constants.dart` remain synchronized.
- **Mandatory Lifecycle Automation:**
  1. Verify with `flutter test`.
  2. Silently increment version via `.agents/hooks/version_increment.py` (minor = elapsed days since `2025-05-27`).
  3. Git sync: `python3 .agents/hooks/git_auto_commit_push.py "<version> - <summary>"`.

## Progressive Disclosure Links

- Product Blueprint: [BIGUESS_PRODUCT_BLUEPRINT.md](file:///home/saoudi26/Documents/GitHub/PERSONAL/BiGuess-Game/BIGUESS_PRODUCT_BLUEPRINT.md)
- Complete Technical Dossier: [PROJECT_DETAILS.md](file:///home/saoudi26/Documents/GitHub/PERSONAL/BiGuess-Game/PROJECT_DETAILS.md)
- Execution Efficiency & Safety Rules: [.agents/rules/](file:///home/saoudi26/Documents/GitHub/PERSONAL/BiGuess-Game/.agents/rules)
- Lifecycle Hooks Configuration: [.agents/hooks.json](file:///home/saoudi26/Documents/GitHub/PERSONAL/BiGuess-Game/.agents/hooks.json)
- Sidecars & Architecture Maps: [.agents/sidecars/](file:///home/saoudi26/Documents/GitHub/PERSONAL/BiGuess-Game/.agents/sidecars)
- Procedural Workflows & Skills: [.agents/skills/](file:///home/saoudi26/Documents/GitHub/PERSONAL/BiGuess-Game/.agents/skills)
