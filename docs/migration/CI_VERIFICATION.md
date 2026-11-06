# CI verification (T03 recheck)

Rechecked **2026-11-06** against the [workflow](../../.github/workflows/ci.yml).
T03 is **partially verified**: workflow triggers and local gates are checked; successful
hosted runs for both a PR and a `main` push remain unverified. The previous runtime,
hermeticity and full acceptance claims were stronger than the available evidence.

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
python3 .agents/scripts/validate_setup.py
python3 -m unittest discover -s .agents/tests -v
```

The manifest check compares the Dart manifest to disk; it does not validate pubspec
asset registration. The asset auditor returns failure for missing/corrupt assets;
other findings can be warnings. Pillow must be installed for image verification.
The version checker is read-only. It replaces the previous
`release.py --version-only` invocation, which rewrites release metadata and can
recompute native-change status/URLs. CI must check versions without repairing them.

Configure branch protection to require **Fast Verification & Quality Gates**.
Reading server-side branch protection returned HTTP 403 (integration lacks access);
it was not changed. A workflow file alone cannot enforce merge policy. Follow `AGENTS.md` for the scoped version/Git
lifecycle after passing checks.

## Executed evidence

[Baseline summary](evidence/2026-11-06-t01-t03/summary.tsv) and
[baseline report](BASELINE.md) record passing local positive gates: 35 Flutter tests,
43 Python tests, analyzer, formatting, inventory, version and setup checks. Local
Python was 3.15.0; hosted Python 3.11/Ubuntu behavior remains to be verified.
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

A read-only GitHub repository Actions API query returned **`total_count: 0`**
([response](evidence/2026-11-06-t01-t03/github_runs.json)): no retained hosted runs
were available at audit time. The commit-specific PR query was also empty; a
`gh run list` fallback failed with a TLS handshake timeout. Remaining T03 acceptance:
obtain hosted PR and `main` run URLs/results and, if required by merge policy,
verify the required status check in branch protection. Do not mark hosted acceptance
complete based only on these local runs.

## Local reproduction

```bash
bash scripts/baseline_check.sh --fast
bash scripts/baseline_check.sh             # additionally stats, doctor, debug APK
```

The script uses the same nine gate commands and preserves each log/exit code under
ignored `.agents/cache/baseline/` by default. An explicit output directory retains
a shareable evidence set. Unlike sequential CI steps, it continues through failures
to collect a complete baseline and returns nonzero if any command fails.
