---
name: debugging
description: Diagnose BiGuess regressions in gameplay, Riverpod lifecycle, assets, animated layout, or updates. Use for failing tests, crashes, missing images, incorrect draws, and update errors.
---

# BiGuess debugging workflow

1. Read `git status --short`; capture the failing command/interaction and exact error. Distinguish existing changes from this task. Consult `.agents/sidecars/known-issues.md` and `test-map.md`; neither proves the current failure has the same cause.
2. Reproduce with the narrowest test or concrete manual steps. Record expected/actual behavior and platform. Use rg or the index skill to locate the call chain; read callers and lifecycle owners before editing.
3. Trace the matching path:
   - **Wrong/missing card:** `topicPackAssets` → `TopicPackDataSource` → `packAssetsProvider` → `GameRoundNotifier` → `SelectCharacterUseCase`. Check exact case/Unicode, bundle registration, unknown-pack empty results, remaining-pool refill, filename-derived names.
   - **Countdown/hint/reset/disposal:** record-keyed `gameRoundProvider`, timer cancellation, explicit clear flags in `GameRoundState.copyWith`, global `showCharacterNameHintProvider`. Read durations from constants/providers.
   - **Layout/animation:** `GameScreen` constraints → card/countdown widgets; reproduce viewport and hint state. Check finite height, keys, image listeners, disposal. Pump bounded durations for repeating animations.
   - **Update failure:** screen/About action → `UpdateController` → version/patch/APK services → `UpdateDialog`. Separate decision logic from network, platform support, cancellation, installation, restart. Shorebird unavailable in ordinary Flutter tests does not prove patch failure.
   - **Record API:** `CloudDatabaseService`/`GameRecord` → `backend/biguess-api/`; this scaffold is outside the current draw flow. Do not add gameplay scoring/winners to diagnose it.
4. Test an evidence-backed cause. For assets run `python3 scripts/generate_manifest.py --check` and `python3 scripts/audit_assets.py` before regenerating. Inject seeded Random for selection; override content/services and dispose test containers. Avoid production requests.
5. Fix at the responsible layer with minimal scope. Preserve user edits and adjacent behavior. Add a regression test when it distinguishes failure from correction, rerun it, then required `flutter test`/analysis checks for Flutter changes.
6. Review the diff and follow repository completion/version guidance. Report cause, correction, results, and unverified platform behavior. Unit tests alone do not prove release/build readiness.
