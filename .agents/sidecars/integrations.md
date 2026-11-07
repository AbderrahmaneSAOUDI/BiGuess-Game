# Assets and external integration map

This is a source map, not a statement of production deployment health. Recheck the referenced files after changes.

## Bundled content: offline gameplay input

`assets/images/<Topic>/<Pack>/` → `scripts/generate_manifest.py` → `lib/assets_manifest.dart:topicPackAssets` plus pubspec asset registration → `TopicPackDataSource` → Riverpod topic/pack providers → topic/pack/game screens.

`AssetLoader.extractCharacterName` derives legacy labels from filenames. Topic icons/colors live in `AppConstants`, with fallbacks for unlisted topics. The static manifest supplies bundled fallback content; verified imported Packs use canonical names/IDs and private files. Cloud records are unrelated to loading packs. Use the `topic-pack-maintenance` skill for bundled content work.

`generate_manifest.py --check` is a read-only Dart-manifest comparison. `--sync-pubspec` writes registration when not in check mode. `manage_topics.py` creates/renames/deletes folders and synchronizes both files. `normalize_filenames.py` uses the current manifest API for optional synchronization. Image conversion requires Pillow; image auditing skips decoding if Pillow is unavailable.

## Local Pack development and installation

`content_inventory.py` records source identity, hashes, validity and explicit provenance. Public fixture export requires declared clearance and revalidates the source bytes. `export_pack.py` produces deterministic full-Pack v1 archives; legacy export requires a development-only opt-in. `LocalPackStore` validates and activates app-private generations. `LocalContentRuntime` verifies those generations and transactionally projects installed metadata into SQLite at startup, with a bundled fallback and explicit rollback define. No network importer or public catalog is implemented.

`check_offline_gameplay.py` proves restart/gameplay in a host network namespace, including process death and private image rendering. Device and published Shorebird-engine validation remain separate; see the migration offline gate.

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

`UpdateController` orchestrates `VersionService`, `ShorebirdPatchService`, and `OtaInstallerService`. Startup/update UI owns the network interaction; gameplay selection uses installed local or bundled snapshot content. The controller first checks the Shorebird runtime when available, then fetches remote metadata. Silent check failures resolve to `UpdateCompleted`; explicit checks can report errors.

- `VersionService` fetches `main/version.json` from the repository's raw GitHub URL, reads package version/build and Android supported ABIs, and computes `UpdateDecision`.
- `RemoteVersion` parses manifest fields and resolves the first matching device ABI, then a universal entry, `apk_url`, or the legacy ARM64 default URL. The release generator supplies one pinned ARM64 URL and matching default/ARM64 SHA-256 checksums; legacy ABI manifests remain supported.
- `ShorebirdPatchService` wraps availability/check/update operations and handles missing runtime/errors. A staged patch requires the controller's restart flow; it is not a new APK.
- `OtaInstallerService` downloads and opens APKs; Android's install flow and platform setup remain relevant. Check real devices for install/restart behavior, beyond pure decision tests.

Version ownership is the triad `pubspec.yaml`, `version.json`, and `AppConstants.defaultVersion`. `scripts/release.py` synchronizes metadata, chooses patch/base release, builds, and can publish. Its `--version-only` path writes local files without building/publishing. Its `--dry-run` prints a read-only plan; it runs no commands or validation. Full releases use an ARM64 APK and Shorebird's managed Flutter engine, uploading the APK before pushing the active branch manifest. Patches require and retain their matching base's URL/checksum metadata. Draft/prerelease paths do not push that manifest. Read the `biguess-ota-release` skill before using it.

`test/unit/update_test.dart` exercises version parsing, manifest/ABI handling, and update decisions. It does not establish deployed URL availability, Shorebird compatibility, artifact freshness, or Android installation success.
