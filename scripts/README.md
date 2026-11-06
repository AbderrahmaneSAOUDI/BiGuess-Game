# BiGuess developer tools

Start here:

```bash
./scripts/run.sh          # Open the menu
./scripts/run.sh --list   # Browse tools by task
./scripts/run.sh --help   # Show commands
```

The menu groups tools into **Check the app**, **Manage content**, and **Build and maintain**. Enter a number or tool name. Use `0`, Escape, or `back` to return. Menu numbers follow display order: **1–4** for checks, **5–10** for content, and **11–15** for running, building and maintenance. Script paths and named shortcuts stay the same.

To run a command directly, add its arguments after the tool name. For example, `./scripts/run.sh manifest --check` checks the image list without opening a menu. Commands report a failed check with a nonzero exit code.

## Find a script

```text
scripts/
├── run.sh                         Start here: menu or command shortcuts
├── menu.py                        Grouped menu and tool list
│
│   Check the app
├── baseline_check.sh              Run verification checks and save every log
├── check_ci_failure_detection.py  Prove the analyzer and test gates reject errors
├── check_offline_gameplay.py      Prove local gameplay survives a restart offline
├── audit_assets.py                Find missing, damaged, or unlisted images
├── content_inventory.py           Count images, record hashes, and check rights
│
│   Manage content
├── manage_topics.py               Add, rename, list, or remove Topics and Packs
├── generate_manifest.py           Update the bundled image list and asset paths
├── convert_and_optimize.py        Resize and compress images
├── normalize_filenames.py         Preview or clean image filenames
├── character_stats.py             Browse names, counts, and possible duplicates
├── export_pack.py                 Create a complete offline test Pack
│
│   Build and maintain
├── build_app.py                   Build APKs, an App Bundle, or the web app
├── release.py                     Prepare versions and publish releases/patches
└── update_version.sh              Compatibility launcher for version tools
```

The section labels organize the list; scripts stay in this directory so existing commands and automation keep working. Repository lifecycle hooks live separately in [`.agents/`](../.agents/README.md).

## Check the app

```bash
# Run all local/CI checks, with a separate log for each result.
# Fast mode skips SDK diagnostics and the Android debug build.
./scripts/run.sh baseline --fast
bash scripts/baseline_check.sh --fast /tmp/biguess-checks

# Include SDK diagnostics and an Android debug build.
bash scripts/baseline_check.sh

# Check bundled images without changing them.
./scripts/run.sh manifest --check
./scripts/run.sh audit

# Check content counts, image integrity, and reproducible inventory output.
./scripts/run.sh inventory --check --check-reproducible

# Include declared test fixtures and refresh the inventory reports.
./scripts/run.sh inventory --include-fixtures --check \
  --output docs/migration/content_inventory.json \
  --markdown docs/migration/CONTENT_INVENTORY_AND_RIGHTS.md

# Run the forced-restart offline test and keep evidence.
./scripts/run.sh offline --evidence /tmp/biguess-offline-evidence
```

The baseline script continues through failed checks and returns failure if any gate fails. Its `summary.tsv` and individual logs show the actual results. Missing diagnostic tools do not prevent later checks from recording their results.

The offline check needs Linux user/network namespaces, `unshare`, `ip`, and a working Flutter SDK with dependencies already resolved. It disables external networking, kills the rendered test app, and reopens the same local storage. It tests the host Flutter engine; Android device checks are documented in the [offline gate](../docs/migration/OFFLINE_GAMEPLAY_GATE.md).

## Manage content

```bash
./scripts/run.sh topics list
./scripts/run.sh topics create-topic "Gaming"
./scripts/run.sh topics create-pack "Gaming" "Original Characters"

# Regenerate the image list and update Flutter asset declarations.
./scripts/run.sh manifest --sync-pubspec

# Preview filename changes; apply only when the preview is correct.
./scripts/run.sh normalize --help
python3 scripts/normalize_filenames.py
python3 scripts/normalize_filenames.py --apply --sync-manifest

# Preview image compression before changing files.
./scripts/run.sh convert assets/images --dry-run

# Search names or list possible duplicates.
./scripts/run.sh stats -s "Luffy"
./scripts/run.sh stats --check-duplicates

# Export cleared fixture metadata and images to a NEW file.
./scripts/run.sh export fixture test/fixtures/cleared_shapes/pack.json \
  --output /tmp/shapes.biguesspack
```

A fixture Pack and every Card must explicitly declare publication clearance, source, license, and attribution. Selecting a folder as a fixture grants no rights. Legacy content stays quarantined. The optional `export_pack.py legacy` command requires `--development-only` and preserves that quarantine.

`content_inventory.py --export-public-test` copies only verified, explicitly cleared images to an empty destination. It verifies the inventoried bytes again before copying. See the [Pack format](../docs/migration/PACK_FORMAT.md) and [content inventory](../docs/migration/CONTENT_INVENTORY_AND_RIGHTS.md).

## Build and maintain

Choose **11 — run**, or open its launch options directly:

```bash
./scripts/run.sh run
```

Choose Debug (default, with hot reload), Profile, or Release. You can list devices,
enter a device ID/name, change the entry-point file, add `KEY=value` Dart defines,
and supply extra Flutter flags. Leave optional fields blank to use Flutter's
defaults. Quote defines with spaces, for example `LABEL="My test build"`.
Flutter stays attached to the terminal for its interactive reload/quit controls.

Pass arguments directly to skip the prompts:

```bash
./scripts/run.sh run --debug -d DEVICE_ID
./scripts/run.sh run --profile -d DEVICE_ID --dart-define=isProTestEnabled=true
./scripts/run.sh run --help  # All options supported by your installed Flutter SDK
```

```bash
./scripts/run.sh build apk --debug
./scripts/run.sh build apk           # Release APK for each Android architecture
./scripts/run.sh build appbundle     # Local Android App Bundle
./scripts/run.sh build web
```

Build checks stop on dependency, analyzer, or test failure. Android release builds require configured release signing; see [release safety](../docs/migration/RELEASE_SAFETY_AND_DISTRIBUTION.md). The ordinary build menu uses Flutter. The explicit `build_app.py --shorebird` option uses `shorebird release` and can register/upload a base release; use it only for deliberate publishing.

```bash
# Inspect a release plan. This runs no build/validation commands, writes no
# files, and performs no upload, commit, tag, or push.
python3 scripts/release.py --full-release --bump patch --dry-run
python3 scripts/release.py --patch --dry-run

# Read-only version consistency check.
python3 .agents/hooks/project_check.py --check
```

`release.py` without flags can publish. Its `--dry-run` is a plan preview, so a successful preview does not prove that a build or test passed. Full releases prepare a source tag, upload APKs, and then push the branch serving the active update manifest. Drafts and prereleases keep that branch manifest unchanged. Generated APK links point to the specific version, so they do not follow an unrelated latest release. Existing staged work stops release Git operations.

Commit app source changes before a release or patch so the release tag matches the built app. Drafts and prereleases require a separate named release-preparation branch; the script refuses `main`, `master`, or detached HEAD. Their metadata commit stays on that branch and only the release tag is pushed. Merging or pushing the preparation branch is a separate deliberate action.

New APK builds must produce all three architecture files during that build; old or duplicate outputs cannot fill a missing architecture. Release metadata includes the SHA-256 hash of each selected APK. `--skip-build` deliberately reuses existing files: verify their version and signing identity before publishing. A failed GitHub creation/upload stops the pipeline and never overwrites assets on an existing release.

For the normal task-completion version bump and scoped commit, follow [the Git workflow](../.agents/skills/git-commit-push/SKILL.md). `release.py --version-only` is a separate release-metadata operation and can regenerate APK URLs.

## Requirements

- Python 3.11 or newer (the version used in CI).
- Pillow for image checks and conversion: `python3 -m pip install Pillow`.
- Flutter/Dart on `PATH` for app checks and builds.
- Android SDK and Java for Android builds; signing credentials for release builds.
- Shorebird and authenticated GitHub CLI only for the publishing operations that use them.

Run `./scripts/run.sh <tool> --help` for the options of a specific command.
