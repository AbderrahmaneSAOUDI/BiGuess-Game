# BiGuess behavioral baseline (T01 recheck)

This is the retained T01 snapshot. For current Phase A/B behavior and checks, read
the [follow-up review](PHASE_AB_REVIEW.md) and [live architecture map](../../.agents/sidecars/architecture.md).

Reinspected on **2026-11-06**, starting at `main` commit
`853f50687084228399062122f926753e6e955824`. The app/platform sources were unchanged
through this audit; CI/script/document corrections are separate from product behavior.
This report supersedes the earlier baseline's incorrect defaults and unverified
diagnosis of its debug-build failure.

The existing annotated rollback tag **`baseline-t01`** resolves to
`50fd964231df5ebedbe7b3aae1d22fbd9d45e4ca` (verified with
`git rev-parse 'baseline-t01^{}'`). It was preserved without moving it or rewriting
history. To inspect it separately: `git worktree add --detach ../BiGuess-baseline baseline-t01`.

## Source-observed behavior

These statements come from code inspection and the tests below; this audit did not
perform an interactive two-phone playtest or signed-release installation.

- [main.dart](../../lib/main.dart) initializes Flutter, requests portrait up/down,
  mounts Riverpod's `ProviderScope`, and opens `TopicsScreen` with Material 3 themes.
  [TopicsScreen](../../lib/presentation/screens/topics/topics_screen.dart) →
  [PacksScreen](../../lib/presentation/screens/packs/packs_screen.dart) →
  [GameScreen](../../lib/presentation/screens/game/game_screen.dart) uses
  `Navigator.push` and animated routes. Each game receives one Topic/Pack name pair.
  Back navigation returns through that stack. The info dialog contains Settings,
  How to Play, About Game and Developers tabs.
- [TopicPackDataSource](../../lib/data/datasources/topic_pack_data_source.dart) reads
  bundled `topicPackAssets`; names are lookup keys. There is no download catalog,
  persisted Card model, difficulty filter, multi-Pack game, Free/Pro quota or match
  round limit in current source.
- [GameRoundNotifier](../../lib/providers/game_controller.dart) is an auto-disposed
  family keyed by Topic/Pack. Mystery-box/button taps start a local periodic countdown,
  hide the old image/name, ignore duplicate countdown taps, then select and reveal a
  bundled image. Disposal/reset cancels the timer; empty content shows the empty state.
- [SelectCharacterUseCase](../../lib/domain/use_cases/select_character_use_case.dart)
  defaults to a no-repeat remaining pool, refilled after exhaustion. Random mode can
  repeat immediately. Display names come from filenames through `AssetLoader`.
  Refresh repeats the countdown/draw indefinitely. There is no score or winner state.
  [AnimatedCharacterCard](../../lib/presentation/widgets/animations/animated_character_card.dart)
  animates entry from a quarter turn; its name control toggles the hint. The previous
  report's claim that tapping the card flips it 180° was incorrect.

Defaults from [settings providers](../../lib/providers/game_settings_controller.dart),
[theme provider](../../lib/providers/theme_controller.dart), and
[AppConstants](../../lib/core/constants/app_constants.dart):

| Setting | Actual default | UI choices / behavior |
| --- | --- | --- |
| Algorithm | `nonRepeating` | Non-repeating or random |
| Countdown | **2 seconds** | **2, 3, 5, 10 seconds** |
| Name hint | **false** | Toggle; reset to hidden on each draw |
| Theme | **`ThemeMode.system`** | Light/dark controls |

All settings are in memory, with no persistence across process restarts.

## Verified image inventory

[Manifest check](evidence/2026-11-06-t01-t03/manifest.txt) and
[asset audit](evidence/2026-11-06-t01-t03/assets.txt) agree on disk/manifest counts.
Pillow 12.3.0 was present for image verification; the audit reported zero issues.
All current playable images are WebP and each Pack directory is registered in
[pubspec.yaml](../../pubspec.yaml).

| Topic | Pack | Disk images | Manifest entries |
| --- | --- | ---: | ---: |
| Anime | Attack on Titan | 131 | 131 |
| Anime | Black Clover | 67 | 67 |
| Anime | Demon Slayer | 43 | 43 |
| Anime | Hunter X Hunter | 135 | 135 |
| Anime | Naruto | 80 | 80 |
| Anime | One Piece | 466 | 466 |
| Geography | Flags | 252 | 252 |
| **2 Topics** | **7 Packs** | **1,174** | **1,174** |

## Network, dependencies and release configuration

The countdown, selection and reveal chain uses local assets without network calls.
`TopicsScreen` starts a silent update check after its first frame; About also offers
a manual check. [UpdateController](../../lib/presentation/controllers/update_controller.dart)
checks Shorebird availability/patches, can stage a patch silently, and otherwise
fetches GitHub raw `main/version.json` through `VersionService`. Optional updates
use a snackbar; required APK updates use a dialog. APKs are downloaded from the
manifest's GitHub Releases URLs through `OtaInstallerService`. Shorebird's checked-in
configuration leaves automatic updating enabled by default. These are update-side
network paths, not evidence of online character selection.
[CloudDatabaseService](../../lib/services/cloud_database_service.dart) exposes
`/health` and GET/POST `/records` at its configured Worker endpoint but is not called
by screens/gameplay. No live backend health or delivery was verified.

[pubspec.yaml](../../pubspec.yaml) specifies Dart `>=3.0.0 <4.0.0`, Riverpod `^2.6.1`,
Dio `^5.7.0`, Shorebird `^2.0.7`, open_filex `^4.5.0`, restart_app `^1.3.2`,
package_info_plus `^10.2.1`, device_info_plus `^13.2.0`, path_provider `^2.1.1`,
path `^1.8.3`, url_launcher `^6.3.1`, staggered animations `^1.1.1` and Cupertino
icons `^1.0.2`. Dev dependencies are Flutter tests, flutter_lints `^6.0.0` and
flutter_launcher_icons `^0.14.3`. Exact resolutions are in `pubspec.lock`.
No SQLite/persistence package is installed.

[Android app configuration](../../android/app/build.gradle.kts) uses namespace and
application ID `com.flutter.gdg_guess_game`, Java/JVM 17, NDK `28.2.13676358` and
Flutter-delegated SDK values. The inspected Flutter SDK resolves min/compile/target
to **24/36/36**. AGP is `9.0.1`, Kotlin plugin declaration `2.3.20`, and Gradle wrapper
`9.1.0`. Release builds use **debug signing**, shrinking/minification and disabled
release lint failure checks. T04 owns remediation; this audit changes none of it.
The version triad at the audited ref is `1.528.69+14`; it is synchronized.
`version.json` uses `/releases/latest/download/` ABI URLs and minimum required version
`0.30.0`; matching published binaries/signatures were not verified.

## Executed checks and remaining limitations

[Context](evidence/2026-11-06-t01-t03/context.txt): Flutter **3.47.9**, Dart **3.13.7**,
Python **3.15.0**, Fedora 46. CI uses Python 3.11; that runner was not reproduced locally.
Full command outputs and exit codes are retained in
[evidence](evidence/2026-11-06-t01-t03/summary.tsv).

| Check | Result / exit code | Log |
| --- | --- | --- |
| Dependency resolution | PASS / 0 | [dependencies](evidence/2026-11-06-t01-t03/dependencies.txt) |
| Formatting | PASS / 0; 58 files, no changes | [format](evidence/2026-11-06-t01-t03/format.txt) |
| Analyzer, fatal infos | PASS / 0 | [analyze](evidence/2026-11-06-t01-t03/analyze.txt) |
| Flutter unit/widget tests | PASS / 0; 35 tests | [tests](evidence/2026-11-06-t01-t03/tests.txt) |
| Manifest and assets | PASS / 0 each; zero asset issues | Inventory logs above |
| Version triad | PASS / 0, read-only check | [versions](evidence/2026-11-06-t01-t03/versions.txt) |
| Agent setup / Python tests | PASS / 0 each; 43 tests | [setup](evidence/2026-11-06-t01-t03/agent_setup.txt), [tests](evidence/2026-11-06-t01-t03/agent_tests.txt) |
| Debug APK | **PASS / 0**, assembleDebug 93.1s | [build](evidence/2026-11-06-t01-t03/debug_build.txt) |
| Flutter doctor | **INCOMPLETE diagnostics despite exit 0** | [doctor](evidence/2026-11-06-t01-t03/doctor.txt) |

No baseline analyzer/test failure reproduced. The former debug AAR metadata failure
also did not reproduce; its claimed AGP/build-directory root cause was not established.
Doctor timed out in Android-toolchain and network-resource checks after 4m30s;
its zero exit code does not establish a healthy toolchain/network. Tests print a
Shorebird-unavailable message in the ordinary Flutter test runtime and still pass.
Existing tests cover content lookup, update decisions/models, record serialization,
root mounting, reveal/hint layout and hint reset; they do not prove deck exhaustion,
full navigation, two-phone interaction, signing, OTA delivery or offline cold starts
on a device. Release signing/lint risks remain T04 work. In-memory settings and absent
SQLite are current behavior, not newly discovered regressions.

The [approved target contracts](DECISIONS.md) add four product Card fields, cumulative
difficulty, multi-Pack selection within one Topic, immutable gameplay snapshots,
Free 5-Pack/10-round limits, safe-point synchronization and deletion tombstones.
These remain migration targets, not implemented features. Hidden-download behavior
and platform/default proposals remain open as documented there.

## Reproduce

From a checkout of the desired ref, with Flutter/Android SDK, Python and Pillow installed:

```bash
bash scripts/baseline_check.sh                  # all checks, doctor and debug APK
bash scripts/baseline_check.sh --fast           # CI gates only
bash scripts/baseline_check.sh /tmp/biguess-audit # explicit output directory
```

The script logs each command and exit code, continues after failed gates, and exits
nonzero if any command fails. Default logs go to ignored `.agents/cache/baseline/`.
It does not modify release metadata, publish artifacts, or install the debug APK.
