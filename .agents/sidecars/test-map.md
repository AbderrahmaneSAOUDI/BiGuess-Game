# Verification map

Run commands from the repository root. Read assertions before reusing tests; names and historical baseline reports are not execution evidence.

| Scope | Command | Existing coverage and limits |
| --- | --- | --- |
| Bundled content | `flutter test test/unit/topic_pack_test.dart` | Topic/pack lookup, nonempty packs, selected inventory expectations, filename parsing, dynamic colors/icons. Does not decode every image or validate future imported Packs. |
| Update decisions | `flutter test test/unit/update_test.dart` | SemVer parsing/comparison, remote JSON parsing, ABI resolution, APK/mandatory/patch decisions. No real delivery or controller lifecycle coverage. |
| Record scaffold | `flutter test test/unit/cloud_database_service_test.dart` | GameRecord JSON conversion and service construction, not API requests or D1 writes. |
| Reveal UI and hints | `flutter test test/widget/game_screen_test.dart` | Card/countdown mounting, countdown entry, name callbacks, stable card position, hint reset. Uses overridden assets; does not exhaust a deck or exercise full navigation. |
| Root smoke | `flutter test test/widget_test.dart` | Mounts BiGuessApp, finds title/topics. Startup may instantiate update services; isolate them for network/error tests. |
| Full Flutter gate | `flutter test` and `flutter analyze` | Suite and static analysis. Analyzer excludes historical/platform directories; passing checks do not verify release configuration. |
| Manifest consistency | `python3 scripts/generate_manifest.py --check` | Compares generated manifest to disk without rewriting. Does not also validate pubspec synchronization. |
| Asset integrity | `python3 scripts/audit_assets.py` | Missing/orphaned/naming/size checks; image corruption checks require Pillow. Inspect output/dependencies before claiming full image validation. |
| Extended baseline | `bash scripts/baseline_check.sh` | Logs dependency/format/analyzer/test, asset/version/tooling checks plus stats, doctor and debug APK build; continues after failures and returns nonzero if any command fails. `--fast` omits stats/doctor/debug build. Does not install or publish artifacts. |
| Agent automation | `.agents/README.md` | Hook/sidecar commands and focused checks; separate these from app behavior verification. |

For a gameplay regression, prove behavior at its owner: seeded selection tests for random/deck behavior, provider tests for timer/reset/disposal, widget tests for layout/navigation. Override `packAssetsProvider((topic: ..., pack: ...))` with bundled test images and dispose `ProviderContainer`; keep auto-disposed providers alive while observing asynchronous transitions. Use bounded `pump(Duration(...))` for repeating animations instead of assuming `pumpAndSettle` terminates.

Verify update cancellation, failed downloads, mandatory/back behavior, and unavailable Shorebird separately from signed APK/patch installation on a supported device. Do not contact production services during unit tests. For a bug, reproduce before fixing and rerun the responsible test; finish with required repository gates. Documentation changes need reference checks, not tests that restate prose.
