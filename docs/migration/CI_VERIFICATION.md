# CI verification (T03 recheck)

Rechecked **2026-11-06** against the [workflow](../../.github/workflows/ci.yml).
T03 is **complete**: the scoped workflow passed on a real pull request and a real
`main` push, including deliberate analyzer/test failure detection on both runners.
The dated local baseline evidence below remains separate from hosted execution.

## Workflow and required checks

The `verify` job (**Fast Verification & Quality Gates**) is configured for pushes
to `main` and pull requests targeting `main`. Obsolete runs on the same ref are
cancelled. Its token has `contents: read`, its timeout is 15 minutes, and it does
not publish artifacts, invoke release tooling, or build release APKs.

| Tool | Configuration |
| --- | --- |
| Runner | `ubuntu-24.04` (runner image updates within this label) |
| Flutter / bundled Dart | **3.47.9 stable / 3.13.7** |
| Python | **3.11** minor series |
| Pillow | **12.3.0** |
| Actions | checkout v4, setup-python v5, flutter-action v2, cache v4; major tags can move |

Flutter uses the setup action's SDK cache. Pub caching includes runner OS, Flutter
version and `pubspec.lock` hash. This reduces repeated downloads; it does not make
dependency resolution hermetic or guarantee a runtime. Update pins intentionally
and rerun formatting/analyzer/tests when changing Flutter/Dart.

All of the following must pass before merge:

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
# When the full agent setup is installed:
python3 .agents/scripts/validate_setup.py
```

The manifest check compares the Dart manifest to disk; it does not validate pubspec
asset registration. The asset auditor returns failure for missing/corrupt assets;
other findings can be warnings. Pillow must be installed for image verification.
CI also runs version-gate regression tests and verifies deliberate analyzer/test
failure detection through `scripts/check_ci_failure_detection.py`, with temporary
fixtures removed in `finally` cleanup. The full agent setup validator runs when
installed; the scoped remote CI installation includes only the checker/helper/tests.
The version checker is read-only. It replaces the previous
`release.py --version-only` invocation, which rewrites release metadata and can
recompute native-change status/URLs. CI must check versions without repairing them.

Configure branch protection to require **Fast Verification & Quality Gates**.
The branch endpoint reports that `main` is unprotected; the dedicated protection
endpoint returned HTTP 403 for the integration. Protection settings were not changed.
A workflow file alone cannot enforce merge policy. Follow `AGENTS.md` for the scoped version/Git
lifecycle after passing checks.

## Executed evidence

[Baseline summary](evidence/2026-11-06-t01-t03/summary.tsv) and
[baseline report](BASELINE.md) record passing local positive gates: 35 Flutter tests,
43 Python tests, analyzer, formatting, inventory, version and setup checks. Local
Python was 3.15.0; scoped hosted Python 3.11/Ubuntu results are recorded in the
completed hosted acceptance section below.
`flutter doctor` exited 0 but had Android/network diagnostic timeouts, so it is not
recorded as healthy. The debug APK built successfully; debug builds are part of
the extended baseline, not this fast CI job.

Deliberate defects were created in uniquely named temporary files and removed in
`finally` cleanup. Full production source files were not overwritten:

| Injection | Exact CI command | Observed outcome |
| --- | --- | --- |
| `final int deliberateCiTypeError = 'wrong type';` in temporary `lib/` Dart file | `flutter analyze --fatal-infos` | **1**, `invalid_assignment`; [log](evidence/2026-11-06-t01-t03/negative_analyze.txt) |
| `expect(1 + 1, 3)` in temporary `test/` test | `flutter test --reporter expanded` | **1**, expected 3, actual 2; [log](evidence/2026-11-06-t01-t03/negative_test.txt) |

[Machine summary](evidence/2026-11-06-t01-t03/negative_summary.json) records these
expected failures. These prove local command failure propagation, not hosted runner
execution. For reproduction, add the same temporary fixtures, run the exact command,
expect nonzero, then remove them and rerun the positive gates before committing.

The [baseline script](../../scripts/baseline_check.sh) also passed a mock-command
control-flow check: an analyzer exit 7 was recorded, later checks including debug
build ran, and the script returned 1; fast mode returned 0 and omitted the debug
build. [Summary](evidence/2026-11-06-t01-t03/script_summary.json). These mock checks
verify script orchestration only; actual Flutter execution is logged separately.

## Hosted acceptance (completed 2026-11-06)

The [published report on GitHub main](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/blob/main/docs/migration/CI_VERIFICATION.md) includes these retained results; [PR #2](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/pull/2) publishes the evidence after the implementation in PR #1.

| Event | Commit | Run | Result |
| --- | --- | --- | --- |
| Pull request [#1](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/pull/1) | `1634363` | [42199913166](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/actions/runs/42199913166) | **SUCCESS** |
| Push to `main` after merge | `d3320af` | [42200303160](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/actions/runs/42200303160) | **SUCCESS** |

Each hosted job passed dependency resolution, formatting, analyzer, all **31 Flutter
tests** on remote main, manifest/asset checks, read-only version verification, Python
syntax and **five version-gate tests**. The failure-detection step required exit 1
with `invalid_assignment` and exit 1 with `Expected: <3>` from real Flutter commands.
The optional full-agent setup validator was skipped because that setup is not yet
installed on remote main; the version helper and its tests were included explicitly.

[Machine results and step conclusions](evidence/2026-11-06-t03-hosted/hosted_runs.json),
[PR log excerpts](evidence/2026-11-06-t03-hosted/pr_verification.txt), and
[main log excerpts](evidence/2026-11-06-t03-hosted/main_verification.txt) preserve the
observed toolchain, passing tests, and both expected failures. Earlier zero-run API
evidence remains a historical snapshot, superseded by these successful runs.

Local `main` and remote `main` have unrelated histories. To complete hosted acceptance
without publishing unrelated local backend, app, migration, or Android work, PR #1
was based on remote `main` at `d4ab660`. Its Dart edits are formatter output required
by the gate. No history was rewritten. The same workflow/failure checks were brought
back to the local branch, which retains its additional tests and full agent setup.
Successful hosted runs cover the scoped remote source, not unpublished local changes.
The local shared checkout was also checked independently at `c5ad3f5`: all gates
passed, including 36 Flutter tests and 54 Python tests. Its transient formatting
failure during concurrent T04 edits was followed by a complete passing rerun; see
[local summary](evidence/2026-11-06-t03-hosted/local_summary.tsv) and
[context](evidence/2026-11-06-t03-hosted/local_context.txt).

## Local reproduction

```bash
bash scripts/baseline_check.sh --fast
bash scripts/baseline_check.sh             # additionally stats, doctor, debug APK
```

The script uses the same required gate commands and preserves each log/exit code under
ignored `.agents/cache/baseline/` by default. An explicit output directory retains
a shareable evidence set. Unlike sequential CI steps, it continues through failures
to collect a complete baseline and returns nonzero if any command fails.
