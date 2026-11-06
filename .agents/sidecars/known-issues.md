# Observed limitations and verification targets

These are source observations, not a severity-ranked tracker or permission to change the product. Reproduce behavior before a fix. Current test/analyzer results belong in the task report, not an evergreen claim here.

| Observation | Evidence and implication |
| --- | --- |
| Android release uses debug signing and disables release lint checks | `android/app/build.gradle.kts`: `signingConfigs.getByName("debug")`, `abortOnError = false`, `checkReleaseBuilds = false`. `TODO.md` T04 owns hardening; passing Flutter tests do not prove release readiness. |
| Startup still performs optional network work | `TopicsScreen.initState` schedules `checkForUpdates(silent: true)` after the first frame. Gameplay draws are local; do not describe the entire app as having zero network requests. `TODO.md` T45 describes the target change. |
| Updater needs platform verification | `version_service.dart`, `ota_installer_service.dart`, and `update_controller.dart` import `dart:io`; native plugins handle installation/restarts. README platform badges do not prove a working web build. |
| Settings are session memory | Theme and gameplay controllers use Riverpod defaults with no persistence adapter. Do not promise restored settings after process restart. |
| New content/session model is a target | Live selection uses image-path lists; canonical Card/Difficulty/GameSession/local SQLite implementations do not exist in `lib/`. Do not report approved target contracts as current behavior. |
| Record persistence is an isolated scaffold | `CloudDatabaseService` and `GameRecord` have no callers in the screen/round flow. Their test checks parsing/construction, not live persistence. Do not wire scores/winners into gameplay without a compatible explicit request. |
| Test coverage is partial | [test-map.md](test-map.md) separates existing checks from unverified deck/timer, update-controller, installer, API, and device behavior. Shorebird warnings in ordinary Flutter runs are not evidence of patch delivery. |

See [integrations.md](integrations.md) for asset-script and release-pipeline limitations. `README.md`, older audits, and prior sidecar prose can contain obsolete inventories, versions, architecture names, or completion claims. Verify against source and current commands.
