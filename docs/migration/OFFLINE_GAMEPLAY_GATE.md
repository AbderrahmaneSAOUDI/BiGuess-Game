# T18 — Local-Pack offline gameplay gate

The native app opens verified `LocalPackStore` generations before mounting its
screens. When installed Packs exist, `contentRepositoryProvider` serves a real
`SqliteContentRepository` projection in application-support storage. Topic → Pack
→ Game Setup → identity → configured rounds uses that repository and the private
image loader. Configuration freezes the local content before play.

`biguess_installed_content.sqlite` is a separate, derived projection. It never
replaces the T08 catalog/sync database (`biguess_content.sqlite`). Each startup
verifies committed generation metadata and images, then replaces the projection
and installed Card snapshots in one SQL transaction. Removed Cards cannot leak
from an earlier projection. A killed transaction rolls back; a committed file
generation can be projected on the next startup. Active games do not write to
SQL, import content, authenticate, or request remote images.

Empty storage, invalid files, and SQL-open/projection errors retain playable
bundled content. Errors are logged at startup. Recovery never deletes a Pack,
resets a database, or overwrites source generations. The explicit
`--dart-define=biguessUseLegacyContent=true` rollback switch selects the bundled
adapter without touching installed content. Keep it until cloud-path verification
and the later legacy-retirement gate.

Automatic application update checks are suppressed when local SQL content is
active. `--dart-define=biguessOfflineDemo=true` also suppresses them for bundled
fallback demonstrations. Manual update actions are outside this gameplay gate.
The gate uses standard Flutter, without the Shorebird engine; it makes no claim
about native updater behavior in a published OTA binary.

## Repeatable automated gate

On a Linux development host with Flutter dependencies/engine/native assets
already installed, Python 3, `unshare`, and `ip`:

```bash
flutter pub get
python3 scripts/check_offline_gameplay.py --evidence /tmp/biguess-t18-evidence
```

The runner requires working user/network namespaces and fails explicitly if they
are unavailable. Each Flutter invocation has a fresh network namespace with only
loopback enabled for Flutter's test protocol: no external interface or route.
The app test additionally traps every Dart HTTP-client construction, verifies
the trap with a canary, and requires zero subsequent attempts. The real update
controller remains in place; it is not replaced by a no-op test controller.

1. Import the original CC0 Colors `.biguesspack` into temporary private storage.
2. Open the real app screens using the startup runtime and SQL binding. Decode
   both private images and navigate through Topic, Pack, Difficulty, and rounds.
3. After the first identity is rendered, signal the external runner. It sends
   `SIGKILL` to the actual `flutter_tester` process during the active game.
4. Delete the source archive copy. Launch a fresh Flutter process against the
   same private storage, still with external networking disabled.
5. Complete ten Hard rounds (Easy + Medium fixture Cards, with deck refill),
   return through Packs, reopen the runtime, and complete three Easy rounds.
6. Check canonical names, rendered private image frames, exact round boundaries,
   zero HTTP-client attempts, SQLite `integrity_check = ok`, and empty
   `foreign_key_check`. No active game resumes after a process restart.

`test/offline/local_pack_gameplay_test.dart` also runs in ordinary `flutter test`
with two isolated runtime/scope lifetimes. The external runner supplies the
stronger process-death and OS network-isolation proof. It supports both the
retained countdown reveal and the session identity/completion screens during
parallel T16/T17 migration.

The checked-in [execution summary](evidence/2026-11-06-t18/summary.json),
[intentional process-death log](evidence/2026-11-06-t18/seed-killed.txt), and
[offline restart log](evidence/2026-11-06-t18/restart.txt) record the host run.
The [repository verification snapshot](evidence/2026-11-06-t18/verification.json)
separately records required checks, including two failures in concurrent
identity-screen work and the resulting withheld version/commit lifecycle.
The killed phase intentionally exits nonzero; only reaching its active-round
marker and then observing a failed/killed process satisfies that phase.
Physical-device, power-loss, and published Shorebird-engine validation are not
claimed. No Android device was attached for this run.

Additional failure checks:

```bash
flutter test test/integration/local_content_runtime_test.dart
```

These cover SQL reopening, legacy rollback, corrupt images without source/DB
rewrites, unsupported database preservation, and projection transaction rollback
under a simulated storage-write failure.

## Android demo without cloud infrastructure

Use a debug build and the original two-color fixture; no server, account, API
key, Studio, or existing downloaded content is needed. File-picker/catalog UI is
outside T18. The explicit developer seed path is read only when that file exists;
later launches reopen installed generations even after the seed is removed.

```bash
flutter build apk --debug \
  --dart-define=biguessOfflineDemo=true \
  --dart-define=biguessLocalPackPath=/data/user/0/com.flutter.gdg_guess_game/files/offline-demo.biguesspack
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell run-as com.flutter.gdg_guess_game mkdir -p files
adb push test/fixtures/local_pack/colors.biguesspack /data/local/tmp/biguess-colors.biguesspack
adb shell run-as com.flutter.gdg_guess_game cp /data/local/tmp/biguess-colors.biguesspack files/offline-demo.biguesspack
adb shell am start -n com.flutter.gdg_guess_game/.MainActivity
```

Verify Colors → Original colors → Game Setup. Enable airplane mode and disable
Wi-Fi, cellular, and any other external transports. Force-stop the app, then
relaunch it without Flutter hot restart:

```bash
adb shell am force-stop com.flutter.gdg_guess_game
adb shell am start -n com.flutter.gdg_guess_game/.MainActivity
```

Choose Hard and ten rounds; confirm Red/Blue images and names, all ten rounds,
and return to Packs. Start another Easy game and confirm only Red is eligible.
Remove the seed copy, force-stop during play, relaunch, and repeat while offline:

```bash
adb shell run-as com.flutter.gdg_guess_game rm files/offline-demo.biguesspack
adb shell am force-stop com.flutter.gdg_guess_game
adb shell am start -n com.flutter.gdg_guess_game/.MainActivity
```

Expected: installed Colors survives, a new game starts, every round renders,
and no login/network/download prompt appears. Optional platform packet capture
should show no app API/auth/image traffic through this flow. Record device/OS,
build SHA, transport settings, observed round count, and capture results when
performing this supplemental device procedure; it has not been performed here.
