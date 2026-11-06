# T03: continuous integration and fast verification

The [workflow](../../.github/workflows/ci.yml) runs **Fast Verification & Quality Gates**
on every PR targeting `main` and every push to `main`. It uses a read-only token,
cancels superseded runs, and has a 15-minute timeout. It never builds release APKs,
publishes artifacts, invokes Shorebird releases, or rewrites release metadata.

## Toolchain and required checks

Flutter **3.47.9 stable** includes Dart **3.13.7**. Python is pinned to **3.11** and
Pillow to **12.3.0** on `ubuntu-24.04`. Flutter SDK caching and a Pub cache keyed by
OS, Flutter version and `pubspec.lock` reduce repeated downloads. Action versions
are major tags; the runner image and Python patch version can change.

The required pre-merge status check is **Fast Verification & Quality Gates**.
Configure branch protection to require that job; workflow configuration alone does
not enforce branch protection.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
python3 scripts/generate_manifest.py --check
python3 scripts/audit_assets.py
python3 .agents/hooks/project_check.py --check
python3 -m compileall -q scripts .agents/hooks
python3 -m unittest discover -s .agents/tests -v
python3 scripts/check_ci_failure_detection.py
```

If the full agent setup is installed, CI also runs its read-only setup validator.
This scoped CI change installs only the version checker and its standard-library
helper/tests; it does not install lifecycle hook configuration or unrelated tooling.
The manifest check compares generated Dart against disk; it does not check pubspec
registration. Missing/corrupt assets fail the asset audit; other findings can warn.
Pillow is installed so image checks execute.

## Failure detection and local reproduction

[check_ci_failure_detection.py](../../scripts/check_ci_failure_detection.py) creates
unique temporary fixtures and removes them in `finally` cleanup. It requires the
actual `flutter analyze --fatal-infos` command to return 1 with `invalid_assignment`
for an integer/String mismatch, then requires a targeted `flutter test` command to
return 1 for `expect(1 + 1, 3)`. Captured diagnostics appear in the Actions log; this
step fails if either deliberate defect is missed. No failing fixture is committed.
Version-check tests exercise synchronized input and version/build/constants drift,
including proof that drift is reported without repairing the fixture.

```bash
bash scripts/baseline_check.sh --fast  # CI commands with per-check logs/exit codes
bash scripts/baseline_check.sh         # also statistics, doctor and debug APK
```

Logs default to ignored `.agents/cache/baseline/`. The script continues after
individual failures and exits nonzero when any gate fails; CI stops failed jobs.
A doctor exit 0 can still include diagnostic failures; inspect its output.

## Scope and execution evidence

This branch is based on remote `main` at `d4ab660`. Local `main` has a rewritten,
unrelated history and additional unpublished work. The scoped T03 branch preserves
both histories and does not publish local backend/app migration work or Android
release edits. Dart source/test changes are formatter output needed for the gate.
The release version triad follows the repository lifecycle and preserves other
release metadata; no production release is made.

Initial remote-source verification passed analyzer and all **31 Flutter tests**.
Formatting initially failed on 29 files and was corrected with `dart format lib test`.
Hosted PR/push run URLs and conclusions will be recorded after execution.
