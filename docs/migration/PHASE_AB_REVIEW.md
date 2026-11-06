# Phase A and B review

Reviewed on **2026-11-06**, starting from local `main` at
`dbc78b8c24fc27c039a4901a63f5cb968c40ad20` and its 31 existing changed paths.
The existing Phase B work was reviewed together with the committed implementation
and preserved. This review covers T01–T18 and the developer scripts. It does not
implement Phase C onward or publish an app, OTA patch, or backend.

The [original baseline](BASELINE.md) remains a historical snapshot. Current source
ownership and navigation are described in the [source map](../../.agents/sidecars/file-map.md)
and [architecture](../../.agents/sidecars/architecture.md).

## Corrections

| Area | Problem | Result |
| --- | --- | --- |
| Local content identity | Repeated Topic/Pack labels could reject otherwise valid installed content and force bundled fallback. Topic totals resolved the first matching label. | Startup permits repeated labels across IDs; counts, selection and Start use the intended IDs. Regression tests include repeated Topic and Pack names, restart, and a renamed Topic. |
| Canonical text | Invalid UTF-16 and control characters could pass model validation and change when encoded or stored. | Models reject invalid text/IDs before serialization while preserving valid multilingual text and emoji. |
| Build gates | Helpers could continue after failed analysis/tests or silently substitute another build engine. | Failed dependencies, analysis or tests stop builds/patches; explicitly requested missing Shorebird tooling fails clearly. |
| Menu errors | Child failures were ignored; invalid release choices could launch the default publishing command. A normal App Bundle choice could register a Shorebird release. | Errors propagate, invalid choices launch nothing, and ordinary menu builds use Flutter. Publishing remains an explicit release operation. |
| Release preview | `--dry-run` could still write versions, commit, push and upload. | It prints a plan and performs no commands or file mutations. A preview does not validate the release. |
| Release publication | The active update manifest could be pushed before APK upload, and URLs followed an unrelated latest release. | Source tag preparation and APK upload precede the active branch manifest push; draft/prerelease operations leave that manifest unpublished. Generated URLs identify the exact version. |
| Release artifacts | Collection could mix stale/duplicate APK outputs, and supplied APKs were ignored when generating checksums. | Publication requires a complete nonempty ABI set, current-build collection rejects stale outputs, and metadata includes SHA-256 hashes from the selected APKs. Explicit reuse with `--skip-build` still requires checking that those binaries match the intended version/signature. |
| Release failure recovery | Git errors could be ignored, unrelated staged work could be committed, and failed patch retargeting could leave version drift. | Git errors stop later steps, existing staged work stops release commits, failed retargeted patches restore their original files, and successful patches synchronize the triad. |
| Release source | Uncommitted app code could differ from the tagged source; draft metadata committed on main could be pushed later by an ordinary sync. | Releases require committed app inputs; drafts/prereleases require a dedicated named preparation branch and push only their source tag. Its local metadata commit must be kept out of the active branch. |
| Inventory accuracy | Reports inferred clearance from a Topic label, overstated validity/duplicate results, failed on empty input, and could let fixtures mask missing source files. Missing Pillow could count unverified images as valid. | Reports derive findings from actual records, reconcile source paths separately from fixtures, and preserve explicit rights and technical validation boundaries. |
| Public fixture export | Previously inventoried bytes could change before copying, and labels could escape the destination. | Export checks hashes/sizes again and restricts outputs to a new destination without overwriting files. |
| Tooling consistency | Filename normalization called obsolete manifest symbols; failed diagnostic collection could prevent baseline gate evidence. | Normalization uses the live API; baseline checks continue recording results after diagnostic failures. |
| Formatting and guidance | The initial formatting check reported 37 files needing formatting; maps still described implemented Phase B systems as future work. | Formatting passes and the maps describe local storage, sessions, ID routing, image loading and verification limits. |

The [toolbox guide](../../scripts/README.md) now has a categorized file tree,
short examples and plain-language task labels. `./scripts/run.sh --list` shows
Check the app, Manage content, and Build and maintain groups. Existing script
paths and shortcuts remain available; baseline, Pack export and offline testing
are also accessible from the menu.

## Acceptance review

| Tickets | Source and acceptance checked |
| --- | --- |
| T01–T03 | Retained rollback baseline, decisions vs open proposals, CI commands, real deliberate-failure detection and complete gate evidence. Hosted results in CI_VERIFICATION.md apply to their recorded remote commits; this review's current-code verification is local. |
| T04 | External Android release signing, enabled app release lint, version/ABI/checksum decisions and guarded release tooling. No signed release installation or real publishing is claimed. |
| T05–T07 | Deterministic source inventory/rights quarantine, cleared fixtures, canonical content validation, adapter/repository order and ID-based navigation. |
| T08–T11 | SQLite create/reopen/upgrades and rollback; installed snapshots independent of cached revisions; deterministic full-Pack export; archive/hash/dimension validation; atomic activation/retry; private image rendering and bounded caches. |
| T12–T15 | Seeded cumulative-difficulty deck, exhaustion/refill, immutable session content/configuration, exact rounds, Free defaults/internal Pro QA and single/multiple/random selection within one Topic. |
| T16–T17 | Canonical name/image display, retained recorded immediate-reveal UX acceptance, loading/errors, accessibility/reduced motion, duplicate dispatch, completion and tier-specific replay. |
| T18 | Imported SQLite content survives actual process death and source removal; restart completes all rounds offline using private images. Bundled rollback remains usable. |

## Verification

The starting tree passed 241 Flutter tests, analysis and 78 Python tests. The
formatting gate reported existing drift. The final app suite passes **244 tests**,
and all **113 Python/tooling tests** pass. Formatting, dependency resolution,
analysis, manifest and asset checks also pass.
The Android debug APK builds successfully.

The independent offline runner isolates external networking in a Linux network
namespace, kills the actual Flutter test app during its first rendered round,
removes the import source, then reopens the same storage in a new process. It
completes ten rounds and another three-round game, with zero HTTP-client attempts,
`PRAGMA integrity_check = ok`, and no foreign-key violations. Its seed-process
nonzero exit is intentional SIGKILL evidence; the restart exits successfully.

[Verification results and logs](evidence/2026-11-06-phase-ab-review/verification.json)
record commands and actual exit codes, including Python/tooling checks and the
expected negative controls. Release/menu failure scenarios use mocks or disposable
fixtures and do not contact publishing services.

Physical-device play, signed APK installation, published Shorebird-engine
networking and cloud synchronization remain separate later gates. Native
Shorebird auto-check policy is not established by the host-engine offline test;
see [the offline gate's limits](OFFLINE_GAMEPLAY_GATE.md). No future catalog,
Studio, remote downloader, commercial billing or final-release acceptance is
implied by Phase A/B completion.
