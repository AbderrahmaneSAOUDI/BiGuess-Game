# Observed limitations and verification targets

These are source-backed limits, not permission to expand scope. Recheck live code before fixing. Current check results belong in the task report.

| Observation | Evidence and implication |
| --- | --- |
| Native update networking needs platform validation | Imported SQLite content suppresses app-level first-frame checks through `automaticUpdateChecksProvider`; legacy fallback retains them. `shorebird.yaml` does not disable native automatic updates. T18 proves the host engine, while T45 owns the broader update-policy reconciliation. |
| Release delivery needs external credentials and device proof | `android/app/build.gradle.kts` requires release signing and enables app release lint. Mock/configuration tests do not prove a signed APK installs or that published metadata matches actual release assets. |
| Settings and sessions are temporary | Theme/legacy settings and `GameSessionNotifier` are in memory. Installed Packs persist; an active round does not resume after process death. |
| Private storage is not perfect DRM | `PrivatePackImages` packages images in app-private containers; see `docs/migration/PRIVATE_IMAGES.md`. Rooted devices and authorized process access remain outside practical protection guarantees. |
| Remote content is future work | The local Pack importer/SQLite/session path exists. Public catalog, Studio and remote download/sync remain Phase C onward; `CloudDatabaseService` is an unrelated record scaffold. |
| Web and native updates have separate support limits | Native startup/storage/updater code imports `dart:io`; platform badges and host tests do not establish a working web build or Android updater. |

See [test-map.md](test-map.md) for verification boundaries and [integrations.md](integrations.md) for script/release entry points. Historical baseline reports intentionally describe older commits; current architecture lives in [architecture.md](architecture.md).
