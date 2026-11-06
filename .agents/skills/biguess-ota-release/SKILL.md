---
name: biguess-ota-release
description: Prepare, diagnose, or publish a BiGuess Android release using the existing version-triad scripts, Shorebird patch/base-release paths, ABI-specific APKs, and update decision tests.
---

# Prepare and release BiGuess

Read `scripts/release.py` and `.agents/sidecars/integrations.md` before a release. A version-sync task does not itself request an app release. Preserve the existing staged/unstaged work; inspect the index before any script that commits.

## Choose the path from live source

`VersionService.evaluateUpdate` selects a full APK for a newer major/minor, a newer native build, or a newer version when the binary lacks Shorebird. Otherwise a newer non-native version selects a Shorebird patch. `UpdateController.checkForUpdates` also checks Shorebird independently before the remote manifest, allowing a patch for an unchanged base version.

- Native/plugin/platform changes require a new base binary. A regular `flutter build apk` does not register a Shorebird base release.
- Dart/UI changes can be patch candidates against an existing Shorebird base. Asset/dependency changes require checking the installed tool's compatibility result; the script's native-diff heuristic is not proof of patchability.
- Date-based patch bumps also recompute the minor from elapsed days since `2025-05-27`; a commit on a new day can therefore change the update path. Do not assume every `--bump patch` preserves major/minor.

## Verify and synchronize locally

```bash
git status --short
flutter test
flutter analyze
python3 scripts/release.py --help
```

For a requested version synchronization:

```bash
python3 scripts/release.py --version-only
```

This writes `version.json` and `AppConstants.defaultVersion` from `pubspec.yaml`; it also regenerates APK URLs and may auto-detect native changes. Supply the actual requested notes/native policy where needed. `--version-only --bump patch` additionally changes pubspec version/build. Keep the triad synchronized: pubspec `version` includes `+build`, manifest `latest_version` excludes it and `build_number` matches it, and constants contain the same version without build metadata.

## Publish only within the authorized release scope

Commands below build/publish and can commit, tag, push, or create GitHub releases:

```bash
python3 scripts/release.py --patch --notes "Requested release notes"
python3 scripts/release.py --full-release --bump patch --native --notes "Requested release notes"
```

Choose one path. The full example is for native changes. A no-flags invocation auto-selects a path and may publish, so do not use it for inspection. `./scripts/run.sh release` opens an interactive wrapper when no flags follow it.

For a local standard Flutter APK build:

```bash
flutter build apk --release --split-per-abi
```

Expected names are `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, and `app-x86_64-release.apk` under `build/app/outputs/flutter-apk/`. The release script requires all three nonempty outputs and rejects stale files after a build. Its Shorebird branch invokes `shorebird release android --artifact apk`; a universal-only result cannot satisfy this split-ABI contract. For explicit `--skip-build` reuse, verify the binaries' intended version and signature before publishing; collection alone cannot prove that match.

## Script limitations to account for

- `--dry-run` prints a read-only plan without commands, version writes, builds, validation, Git or uploads. It proves planning only; run the actual local gates separately.
- The patch pipeline validates native changes and Flutter analysis/tests before retargeting an active Shorebird base. A failed patch restores original pubspec/constants; success synchronizes and commits the whole triad. Existing staged work stops release commits.
- Build/patch validation failures stop the pipeline unless checks are explicitly skipped. Full releases prepare a source tag, upload APKs, then push the active branch manifest. Draft/prerelease paths leave that manifest unpublished.
- Generated APK URLs are pinned to `v<version>` with an ARM64 fallback. Verify the actual ABI artifacts, version and signature before publishing; a version manifest alone does not prove correct binaries.

For runtime update changes, run `flutter test test/unit/update_test.dart` and review `SemVer`, `RemoteVersion.resolveApkUrl`, `UpdateController`, and `OtaInstallerService` together. Do not publish a test manifest or upload a patch merely to validate the decision engine.
