# Assets and external integration map

This is a source map, not a statement of production deployment health. Recheck the referenced files after changes.

## Bundled content: offline gameplay input

`assets/images/<Topic>/<Pack>/` → `scripts/generate_manifest.py` → `lib/assets_manifest.dart:topicPackAssets` plus pubspec asset registration → `TopicPackDataSource` → Riverpod topic/pack providers → topic/pack/game screens.

`AssetLoader.extractCharacterName` derives labels from filenames. Topic icons/colors live in `AppConstants`, with fallbacks for unlisted topics. The static manifest is authoritative for available game content; cloud records are unrelated to loading packs. Use the `topic-pack-maintenance` skill for content work.

`generate_manifest.py --check` is a read-only Dart-manifest comparison. `--sync-pubspec` writes registration when not in check mode. `manage_topics.py` creates/renames/deletes folders and synchronizes both files. The filename normalizer's optional sync path still imports obsolete generator symbols; invoke the generator separately. Image conversion requires Pillow; image auditing skips decoding if Pillow is unavailable.

## Optional Cloudflare game-record API

| Boundary | Current source behavior |
| --- | --- |
| Worker | `backend/biguess-api/src/index.js` handles health, records, and CORS OPTIONS. |
| Storage | `schema.sql` defines `game_records` and a topic/pack index; `wrangler.json` binds D1 as `biguess_db`. |
| Client | `CloudDatabaseService` uses injectable Dio/base URL and eight-second connect/receive timeouts. |
| Codec | `GameRecord.toJson` emits camelCase counters; D1 rows use snake_case counters; `fromJson` accepts both. |
| Integration | The service/provider currently has no gameplay consumers in `lib/`. No local queue, caching, or automatic upload exists. |

`GET /records` reads the newest 50 rows. `POST /records` validates required field presence and binds an INSERT; errors return JSON and status 400/500. Health returns `ok` without testing the database binding. CORS is wildcard; no authentication or rate limiting is implemented. `CloudDatabaseService.checkHealth` returns false on failure; record methods can throw exceptions. The existing Dart test covers codecs and construction, not request execution or Worker behavior.

Do not add this API to the synchronous selection/countdown path. `npm run dev` and `npm run deploy` are distinct package scripts; deployment and remote schema application are separate from a Flutter release. See the `backend-development` skill.

## Android hybrid updates

`UpdateController` orchestrates `VersionService`, `ShorebirdPatchService`, and `OtaInstallerService`. Startup/update UI owns the network interaction; gameplay selection uses bundled assets. The controller first checks the Shorebird runtime when available, then fetches remote metadata. Silent check failures resolve to `UpdateCompleted`; explicit checks can report errors.

- `VersionService` fetches `main/version.json` from the repository's raw GitHub URL, reads package version/build and Android supported ABIs, and computes `UpdateDecision`.
- `RemoteVersion` parses manifest fields and resolves the first matching device ABI, then a universal entry, `apk_url`, or the ARM64 default URL. The current release generator supplies the three ABI URLs and an ARM64 `apk_url`.
- `ShorebirdPatchService` wraps availability/check/update operations and handles missing runtime/errors. A staged patch requires the controller's restart flow; it is not a new APK.
- `OtaInstallerService` downloads and opens APKs; Android's install flow and platform setup remain relevant. Check real devices for install/restart behavior, beyond pure decision tests.

Version ownership is the triad `pubspec.yaml`, `version.json`, and `AppConstants.defaultVersion`. `scripts/release.py` synchronizes metadata, chooses patch/base release, builds, and can publish. Its `--version-only` path writes local files without building/publishing. Its `--dry-run` is **not** a dry run of the entire pipeline. Read the `biguess-ota-release` skill before using it.

`test/unit/update_test.dart` exercises version parsing, manifest/ABI handling, and update decisions. It does not establish deployed URL availability, Shorebird compatibility, artifact freshness, or Android installation success.
