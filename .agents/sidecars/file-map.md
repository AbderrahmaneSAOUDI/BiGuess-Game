# BiGuess source map

Paths below describe the live tree. Read [architecture.md](architecture.md) for behavior, [integrations.md](integrations.md) for content/backend/release pipelines, and [test-map.md](test-map.md) for verification. The generated index in `.agents/cache/` is a navigation aid; confirm symbols against source.

| Change area | Entry points |
| --- | --- |
| Startup, orientation, root theme | `lib/main.dart` (`main`, `BiGuessApp`) |
| Topic → Pack → Game navigation | `lib/presentation/screens/topics/topics_screen.dart`, `lib/presentation/screens/packs/packs_screen.dart`, `lib/presentation/screens/game/game_screen.dart` |
| Round state and countdown | `lib/providers/game_controller.dart` (`GameRoundNotifier`, `gameRoundProvider`); `lib/domain/models/game_state.dart` (`GameRoundState`) |
| Random/non-repeating selection | `lib/domain/use_cases/select_character_use_case.dart` (`SelectCharacterUseCase`); `lib/domain/models/character_algorithm.dart` |
| Algorithm, countdown, hint, theme settings | `lib/providers/game_settings_controller.dart`, `lib/providers/theme_controller.dart`; `lib/presentation/dialogs/info/tabs/settings_tab.dart` |
| Bundled content lookup | `lib/data/datasources/topic_pack_data_source.dart`; `lib/providers/topic_pack_providers.dart`; generated `lib/assets_manifest.dart` (`topicPackAssets`) |
| Content generation and checks | `scripts/generate_manifest.py`, `scripts/audit_assets.py`, `scripts/character_stats.py`; `assets/images/<Topic>/<Pack>/`; `pubspec.yaml` |
| Filename-derived display names | `lib/core/utils/asset_loader.dart` (`AssetLoader.extractCharacterName`) |
| Topic styling and shared copy | `lib/core/constants/app_constants.dart`; `lib/core/theme/app_colors.dart`; `lib/core/theme/app_theme.dart` |
| Reveal/countdown/mystery animations | `lib/presentation/widgets/animations/`; `lib/presentation/screens/game/widgets/game_empty_state.dart` |
| Rules, settings, about, credits | `lib/presentation/dialogs/info/game_info_dialog.dart`; adjacent `tabs/` and `widgets/` |
| Update orchestration | `lib/presentation/controllers/update_controller.dart`; `lib/domain/models/update_state.dart`, `update_decision.dart`, `remote_version.dart`, `sem_ver.dart` |
| Remote version / patch / APK services | `lib/services/version_service.dart`, `shorebird_patch_service.dart`, `ota_installer_service.dart`; `lib/presentation/dialogs/update/update_dialog.dart` |
| Displayed installed version | `lib/presentation/controllers/app_version_controller.dart` (`appVersionProvider`) |
| Optional record API scaffold | `lib/services/cloud_database_service.dart`, `lib/domain/models/game_record.dart`; `backend/biguess-api/src/index.js`, `schema.sql`, `wrangler.json` |
| Developer/release commands | `scripts/run.sh`, `scripts/menu.py`, `scripts/release.py`, `scripts/build_app.py`, `scripts/README.md` |
| Migration contracts and ordering | `docs/migration/DECISIONS.md`, `TODO.md`, relevant sections of `BIGUESS_PRODUCT_BLUEPRINT.md` |
| Historical evidence | `docs/migration/BASELINE.md`, `CURRENT_ARCHITECTURE_AUDIT.md`; verify dated claims before reuse |
| Agent automation | `.agents/README.md`, root `AGENTS.md`, `.agents/hooks.json`, `.agents/skills/`, `.agents/rules/` |

`old-lib/` and `old-test/` are historical copies, excluded by `analysis_options.yaml`. Implement in `lib/` and `test/`. `ChatGPT/` and `Obsidian/` contain reference material, not application entry points.
