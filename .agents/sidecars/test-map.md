# Verification map

Run commands from the repository root. Tests and dated reports have different scopes; inspect assertions before claiming platform or release readiness.

| Area | Focused tests or command | What it proves / limits |
| --- | --- | --- |
| Canonical content | `flutter test test/unit/content_models_test.dart test/unit/content_repository_test.dart test/unit/cleared_fixture_pack_test.dart` | Serialization, validation, relationships, stable IDs and legacy adapter; no cloud publishing. |
| SQLite and migrations | `flutter test test/integration/sqlite_content_repository_test.dart test/integration/installed_content_revision_test.dart` | Create/reopen/upgrade, constraints, installed snapshots and transactional failure rollback. |
| Pack files and private images | `flutter test test/unit/local_pack_store_test.dart test/unit/pack_entitlement_test.dart test/widget/content_image_loader_test.dart` | Archive validation, tampering, atomic activation/retry, storage limits, private rendering and cache bounds. No claim of perfect DRM. |
| Startup and content identity | `flutter test test/integration/local_content_runtime_test.dart test/integration/local_content_identity_test.dart test/widget/content_navigation_test.dart` | SQL projection, fallback, repeated display names, ID-based counts/routes and local restart. |
| Local deck and sessions | `flutter test test/unit/card_selection_engine_test.dart test/unit/game_session_test.dart test/integration/game_session_content_test.dart` | Seeded non-repeat deck, difficulty, exact rounds, Free/Pro transitions and immutable content/files during updates. |
| Pack selection | `flutter test test/unit/pack_selection_test.dart test/integration/pack_selection_repository_test.dart test/widget/pack_selection_screen_test.dart` | Single/multiple/random within one Topic, unavailable content, stable IDs and merged Cards. |
| Game setup | `flutter test test/unit/game_setup_test.dart test/integration/game_setup_content_test.dart test/widget/game_configuration_screen_test.dart` | Defaults, access rules, installed-content validation, Start navigation and frozen settings. |
| Identity and completion | `flutter test test/widget/identity_card_test.dart test/widget/session_identity_screen_test.dart test/widget/game_completion_test.dart` | Names/local images, loading/errors, accessibility, reduced motion, stale taps, exact completion and replay routing. |
| Offline process restart | `python3 scripts/check_offline_gameplay.py --evidence /tmp/biguess-offline` | SIGKILL during a rendered round, source removal, fresh process, SQL/private images and all rounds in a Linux network namespace. Host Flutter engine only; device/published OTA-engine validation is separate. |
| Legacy bundled gameplay | `flutter test test/unit/topic_pack_test.dart test/widget/game_screen_test.dart test/widget_test.dart` | Bundled inventory/lookups, countdown/reveal/hints and root mounting. |
| Update decisions | `flutter test test/unit/update_test.dart` | SemVer/manifest/ABI and APK/patch decisions; no signed installation or real patch delivery. |
| Optional record scaffold | `flutter test test/unit/cloud_database_service_test.dart` | Codec/construction only; no live Worker or D1 validation. |
| Full app gates | `flutter test`, `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test` | Tests/static analysis/formatting; no release-signing or physical-device proof. |
| Bundled manifest and assets | `python3 scripts/generate_manifest.py --check`, `python3 scripts/audit_assets.py` | Disk/manifest alignment and asset checks. Pillow is needed for image decoding; manifest check alone does not verify pubspec registration. |
| Export and quarantine | `python3 -m unittest discover -s .agents/tests -p 'test_*inventory*.py'`, `python3 -m unittest discover -s .agents/tests -p 'test_pack_export.py'` | Deterministic inventory/rights and full-Pack export fixtures; no permission to publish legacy content. |
| Tooling and setup | `python3 .agents/scripts/validate_setup.py`, `python3 -m unittest discover -s .agents/tests -v` | Configuration, hooks, scoped Git/versioning, CI/release safety and script behavior in temporary/mock environments. |
| Full baseline | `bash scripts/baseline_check.sh` | Logs gates, statistics, doctor and debug APK; continues after failures and returns nonzero if any gate fails. `--fast` skips statistics/doctor/build. |
| CI negative controls | `python3 scripts/check_ci_failure_detection.py` | Temporary real analyzer/test errors must produce the expected nonzero result. Run serially with other Flutter checks. |

Use bounded pumps for repeating animations; `pumpAndSettle` may never settle. Override content/services and dispose test containers. Keep Flutter jobs serial in this shared checkout. Tests that simulate failures or Git operations use isolated fixtures and do not publish.

For updates, verify cancellation, installation, restart and signatures on a supported device separately. Ordinary Flutter test runtimes lack the Shorebird engine; that warning does not establish patch health. Core gameplay never depends on the record API or cloud availability.
