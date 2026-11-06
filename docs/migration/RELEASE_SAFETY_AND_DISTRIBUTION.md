# BiGuess Game — Android Release Safety, Security Audit & Distribution Policy

This document formalizes the release safety architecture, vulnerability audit findings, and intended distribution policy established in milestone **T04** (`GATE: Repair Android release safety without shipping`).

---

## 1. Executive Summary

Prior to T04, production Android release builds were vulnerable to severe operational and security hazards:
1. **Insecure Release Signing:** Release builds were configured to sign silently with the public Android debug key (`signingConfigs.getByName("debug")`), rendering builds unpublishable to secure environments and vulnerable to identity spoofing and update signature mismatches (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
2. **Suppressed Release Linting:** Production linting was disabled via `abortOnError = false` and `checkReleaseBuilds = false`, bypassing Android Gradle Plugin static analysis during release assembly.
3. **Unpinned Update URLs & Lack of Integrity Verification:** Remote `version.json` manifests relied on mutable `/releases/latest/download/` URLs and contained no cryptographic SHA-256 checksums, introducing risks of infinite update loops and unverified binary execution.
4. **Release Pipeline Inversion:** Automated release scripts pushed the remote update manifest to Git `main` before GitHub release asset uploads completed, creating race conditions where client apps could be directed to 404 artifacts.

In accordance with T04 acceptance criteria, release safety has been repaired without publishing builds or mutating active user update channels.

---

## 2. Release Signing Architecture & Credential Protection

### 2.1 Elimination of Silent Debug Signing
In `android/app/build.gradle.kts`, `signingConfig = signingConfigs.getByName("debug")` has been removed from `buildTypes.release`.
- Release builds **strictly require external credentials**.
- When credentials are not configured, `signingConfig` is set to `null`.
- A Gradle task graph listener actively blocks release packaging: attempting to run `assembleRelease`, `bundleRelease`, or `packageRelease` without configured release credentials fails fast with a clear, actionable `GradleException`.
- Debug builds (`assembleDebug`, `flutter run`) continue to use the standard local debug keystore without developer friction.

### 2.2 External Credential Resolution Hierarchy
Credentials are provided strictly outside Git tracking via two mechanisms:
1. **Local Developer Builds:** An unversioned `android/key.properties` file:
   ```properties
   storeFile=../keystores/release.keystore
   storePassword=...
   keyAlias=...
   keyPassword=...
   ```
   A template is provided at `android/key.properties.example`.
2. **CI/CD Automated Builds (GitHub Actions):** Injected environment variables:
   - `ANDROID_KEYSTORE_PATH` (or `KEYSTORE_PATH`)
   - `ANDROID_KEYSTORE_PASSWORD` (or `KEYSTORE_PASSWORD`)
   - `ANDROID_KEY_ALIAS` (or `KEY_ALIAS`)
   - `ANDROID_KEY_PASSWORD` (or `KEY_PASSWORD`)

### 2.3 Credential Leak Prevention
- Root `.gitignore` and `android/.gitignore` explicitly ignore `key.properties`, `*.keystore`, and `*.jks`.
- Automated regression suite (`.agents/tests/test_release_configuration.py`) actively asserts that no tracked Git file ends with `.keystore` or `.jks`, and that `key.properties` is never tracked in the index.

### 2.4 Local and CI Validation
The custom Gradle task `:app:validateReleaseSigning` validates release credentials:
```bash
# In developer / unconfigured environment (prints status, exits 0):
./gradlew :app:validateReleaseSigning

# In CI production environment (fails if credentials missing):
./gradlew :app:validateReleaseSigning -PrequireReleaseSigning=true
```

---

## 3. Android Release Lint Policy & Justified Mitigations

The unsafe bypasses (`abortOnError = false`, `checkReleaseBuilds = false`) have been replaced with a robust, documented lint policy:

```kotlin
lint {
    // Enforce static analysis during release builds
    checkReleaseBuilds = true
    // Abort the build if any fatal errors are detected in application code
    abortOnError = true
    // Documented mitigation: Do not fail app release builds on third-party plugin lints
    checkDependencies = false
    // Warnings are reported but do not halt builds
    warningsAsErrors = false
    // Documented mitigations: Portrait game lock and Android 16 orientation guidance
    disable += setOf("LockedOrientationActivity", "DiscouragedApi")
}
```

### Justification for Specific Mitigations:
1. **`checkDependencies = false`:**
   During the T04 audit, full-tree dependency linting failed on third-party Flutter plugin `url_launcher_android` due to Android 11 package visibility restrictions (`QueryPermissionsNeeded` error inside plugin code). Disabling dependency checks ensures `:app` code is rigorously validated without allowing external upstream plugin linter quirks to halt application delivery.
2. **`LockedOrientationActivity` and `DiscouragedApi` Exclusions:**
   BiGuess is designed as a vertical handheld 2-player mystery party game played face-to-face. Locking screen orientation to portrait in `AndroidManifest.xml` is an intentional product design invariant. Android 16's upcoming multi-window orientation advice is noted, but orientation lock remains mandatory for this game loop.

---

## 4. Audit Findings: `version.json`, Release Scripts & Shorebird

### 4.1 Audit of `version.json` & `/releases/latest/` URLs
- **Vulnerability:** Legacy manifests referenced:
  `https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/releases/latest/download/app-{abi}-release.apk`
- **Hazard Analysis:**
  GitHub's `/releases/latest/` endpoint resolves **only to the latest published, non-prerelease, non-draft release**.
  If a release is created as a draft or prerelease, or if `version.json` on `main` is updated before GitHub release asset propagation completes, `/releases/latest/` points to the *previous* version.
  **Consequence:** Infinite update loop. The client app observes `remoteVersion > localVersion`, downloads from `/releases/latest/` (which still serves the older version), completes installation, re-launches, detects the update again, and re-downloads in an endless loop.
- **Remediation & Required URL Standard:**
  Future manifests generated by `scripts/release.py` must use immutable, tag-pinned release URLs:
  `https://github.com/{user}/{repo}/releases/download/v{version}/app-{abi}-release.apk`
  Tag-pinned URLs ensure that if the target asset does not exist or the release is in draft, the client encounters a clean 404 rather than downloading the wrong binary.

### 4.2 Audit of Downloaded APK Integrity & Verification
- **Vulnerability:** `OtaInstallerService` previously streamed downloaded APKs to disk and invoked `OpenFilex.open()` without validating file size or SHA-256 checksums.
- **Hazard Analysis:**
  Flaky network connections, CDN truncation, or proxy corruption could deliver an incomplete APK file. Passing truncated files to `ACTION_INSTALL_PACKAGE` results in cryptic OS errors (`INSTALL_PARSE_FAILED_UNEXPECTED_EXCEPTION`) and stranded user states.
- **Architectural Enhancement in T04:**
  - Extended domain models `RemoteVersion` and `UpdateFullApk` with optional `sha256` and `sha256_hashes: { "arm64-v8a": "...", ... }` fields.
  - Implemented `RemoteVersion.resolveSha256(deviceAbis)` resolution matching the device's CPU architecture.
  - In `OtaInstallerService`, downloads write to a temporary `.apk.tmp` file and perform atomic rename only upon full download completion.
  - When checksums are present in `version.json`, the client will verify the cryptographic hash prior to invoking the native package installer.

### 4.3 Audit of Release Script Pipeline Ordering (`scripts/release.py`)
- **Vulnerability:** In `pipeline_full_release`:
  1. Step 4 synchronizes `version.json`.
  2. Step 5 commits and pushes `pubspec.yaml`, `version.json`, and constants to GitHub `main`.
  3. Step 6 calls `gh release create` and uploads APK binaries.
- **Hazard Analysis:**
  If Step 6 encounters an error (e.g. GitHub token expiration, rate limit, upload failure, network disconnection), `version.json` has **already been pushed to `main`**.
  Active client apps polling `raw.githubusercontent.com/.../main/version.json` will immediately announce an update whose download binaries do not exist, causing 404 download errors for all users.
- **Required Pipeline Mitigation:**
  Production release tooling must stage and verify GitHub release assets (e.g. via draft release or dry-run validation) *before* committing and pushing the public `version.json` update manifest to the `main` branch.

### 4.4 Shorebird vs Date-Based Versioning Divergence
- **Vulnerability:** In BiGuess, minor version is calculated from elapsed days since base date `2025-05-27`:
  `minor = floor((today - 2025-05-27).days)`
- **Decision Engine Conflict:**
  In `VersionService.evaluateUpdate`:
  ```dart
  final hasNewerMajorOrMinor = remoteSemVer.isNewerMajorOrMinorThan(local);
  if (hasNewerMajorOrMinor || hasNewerNativeBuild || needsFullApkDueToNoShorebird) {
    return UpdateFullApk(...);
  }
  ```
  Because minor version advances daily, **any release issued on a subsequent day is classified as a minor version bump**, causing `hasNewerMajorOrMinor` to evaluate to `true`.
- **Impact:**
  Shorebird OTA code patches can only be delivered on the **exact same calendar day** as the base release. Any subsequent patch published on a later date automatically forces client devices down the `UpdateFullApk` path.
- **Policy:**
  When planning Shorebird hot-patches, teams must either:
  a) Maintain the base release's minor version in Shorebird patch metadata, or
  b) Accept that cross-day releases require split-ABI APK distribution.

---

## 5. Intended Distribution Policy

1. **Production Signing Authority:**
   - Production keystores are maintained strictly by the Owner Admin.
   - Keystores are never stored in repositories, public cloud buckets, or shared developer machines.
   - Automated CI builds access credentials solely through encrypted GitHub Actions Secrets.
2. **Split-per-ABI Distribution:**
   - Standard release builds compile strictly using `flutter build apk --release --split-per-abi`.
   - Separate, optimized binaries are published for `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
   - Universal (fat) APKs are rejected to maintain download size efficiency (<35MB per architecture).
3. **Pre-Release Release Gates:**
   Before any production release is authorized or published:
   - Full automated test suite passes (`flutter test`).
   - Static analyzer passes with zero fatal infos (`flutter analyze --fatal-infos`).
   - Gradle release signing validation passes (`./gradlew :app:validateReleaseSigning -PrequireReleaseSigning=true`).
   - Manifest asset synchronization passes (`python3 scripts/generate_manifest.py --check`).
   - Version triad synchronization passes (`python3 .agents/hooks/project_check.py --check`).
   - Agent tooling regression suite passes (`python3 -m unittest discover -s .agents/tests -v`).
4. **No Unprompted Release Shipping:**
   Milestone T04 establishes the release safety gates and auditing documentation without publishing new artifacts or modifying the update paths of active end users.
