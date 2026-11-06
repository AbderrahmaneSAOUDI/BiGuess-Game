# BiGuess — Ordered Coding-Agent Implementation Roadmap

**Prepared:** 2026-11-05  
**Repository:** https://github.com/AbderrahmaneSAOUDI/BiGuess-Game  
**Audited branch / HEAD:** `main` at `d4ab660faacd1c4f923278456b29f58755ae7040` (2026-09-26)  
**Requirements baseline:** the supplied `BIGUESS_PRODUCT_BLUEPRINT.md` (10,154 lines), especially **Game Model**, **Content System**, **Technical Architecture**, **BiGuess Content Studio**, **Distribution & Updates**, **MVP**, and **Migration Plan From Current BiGuess**. The same-named file is also present in the repository.

## How to use this file

**Current status:** Phases A and B have implementations in the live tree. The [Phase A/B review](docs/migration/PHASE_AB_REVIEW.md) records follow-up fixes and verification. The starting audit below describes the older audited commit, not today's dependencies or gameplay. Read the current [source map](.agents/sidecars/file-map.md) for navigation.

Give your coding agent **one numbered ticket at a time**, in ascending order. Each ticket should normally yield one small, reviewable PR. Confirm the acceptance criteria and merge before giving the next ticket. Tickets marked **GATE** require explicit acceptance before continuing.

**Architectural Workstreams Alignment:**
The updated `BIGUESS_PRODUCT_BLUEPRINT.md` establishes that BiGuess consists of **three parallel workstreams with explicit dependencies**:
* **Workstream A (Mobile App):** Local Game Engine, game configuration, local content storage, offline gameplay, discovery/download manager, and safe non-interrupting synchronization.
* **Workstream B (Content Studio):** Google/Firebase authentication, role permissions, Topic/Pack/Card management, bulk image import & normalization, automated validation rules, and publishing.
* **Workstream C (Content Backend):** Shared models, D1 database & migrations, Workers API contracts, R2 image bucket, catalog distribution, incremental sync, and deletion tombstone propagation.

While this roadmap organizes execution serially for a single-agent workflow, this ticket order is an execution strategy rather than a hard technical lock-step dependency. In team environments, Workstream A (Mobile), Workstream B (Studio), and Workstream C (Backend) can proceed in parallel once shared contracts (T06/T19) are established. All ticket contracts and milestones strictly preserve this inter-workstream dependency structure: shared contracts (T06/T19) are agreed upon early; backend foundations (T20–T25) support both Studio and Mobile; Studio (T26–T38) produces and validates real content in parallel; and Mobile (T39–T45) integrates remote distribution without blocking local gameplay development.

**Universal agent contract (prepend to every ticket):**

> Read `BIGUESS_PRODUCT_BLUEPRINT.md` and inspect the current code relevant to this ticket. Implement **only the requested ticket**; do not rewrite unrelated systems, expand MVP scope, or silently reinterpret requirements. Preserve a playable app and migration rollback path. Use the current default branch as your base, not the old audited SHA if the branch has advanced. Add or update automated tests. Run the relevant checks (`flutter analyze`, `flutter test`, asset audit / backend tests as appropriate), report what actually ran and any failures, and provide the changed-file list, behavioral changes, migration impact, and PR/commit reference. Avoid speculative abstractions. Do not publish third-party content or run destructive cloud operations without explicit approval. If a ticket depends on a product/legal decision, document the blocker rather than inventing a decision.

**Quality gates:** `flutter analyze` and `flutter test` must pass when Flutter changes are made, or failures must be identified as baseline failures and resolved in an agreed follow-up. Backend and Studio work needs its own automated tests and local build checks. All new migrations/imports must be idempotent or safely retryable, and new content must be validated before activation. Never hardcode production secrets.

## Historical starting audit (before Phases A and B)

- Current `pubspec.yaml`: `0.36.0+3` with Flutter, Riverpod, and legacy APK/Shorebird update dependencies; **no** SQLite/content-backend stack yet. `version.json` also names `0.36.0` while the latest published GitHub Release is `v0.30.5`; `v0.36.0` is a draft.
- The latest source already has `TopicsScreen` and `PacksScreen`, and source assets under `assets/images/Anime/<Pack>` and `assets/images/Geography/Flags`. The generated `assets_manifest.dart` drives `TopicPackDataSource`; these are **not** downloadable cloud Packs.
- Repo tree contains **922 Anime images in six Packs** (131 Attack on Titan, 67 Black Clover, 43 Demon Slayer, 135 Hunter X Hunter, 80 Naruto, 466 One Piece) **plus 252 Geography flag images**; these are repository file counts, not legal-clearance or content-quality statements.
- `GameRoundNotifier` still runs a countdown, selects image paths, and supports endless refresh; `SelectCharacterUseCase` supports random/non-repeating modes. No configured game length, card difficulty, true Card entity, local content DB, or remotely managed pack lifecycle.
- `TopicsScreen.initState` makes a *silent* version check after first frame; the latest commit also displays mandatory update dialogs. This is not the earlier blocking splash flow described in some historical audit notes, but it still introduces launch-path network activity that must be reconciled with the blueprint.
- `android/app/build.gradle.kts` signs release with `signingConfigs.getByName("debug")` and disables release lint failure. The README still advertises `v0.25.0` and a predominantly anime-only two-player concept. There is no `.github/workflows/`, `backend/`, or `studio/` in the audited main tree. `old-lib/` and `old-test/` remain as historical copies.
- Four current test files exist under `test/`; this review **read source/tests** but did not run Flutter tooling. Do not report CI/build health as verified.

### Historical commits that affect migration

1. **Aug 26:** `747b462` (`v0.31`) followed by `39388b2` (`release: v0.30.5`) demonstrates version-history drift; treat tags, APKs, versions, and update URLs cautiously.
2. **Sep 9:** `efa26c8` and `4a6dfb3` altered project organization and documentation; the retained legacy tree is reference material, not the architecture to extend.
3. **Sep 25:** `193cf58`, `26455ef`, `d988235`, `4e0fb03` introduced nested Topic/Pack assets, Geography flags, dynamic topic theming, tooling updates, and WebP conversion. **Preserve/reuse** this work.
4. **Sep 26:** `c78c652` added/refactored info UI and OTA update plumbing, `017dfc4` set release metadata to 0.36.0, and **HEAD `d4ab660`** added mandatory update handling and moved old project files to `old-lib/` / `old-test/`. Do **not** assume updating has already been removed for the new architecture.

---

# PHASE A — Freeze, verify, and make migration safe

### [x] T01 — GATE: Freeze the behavioral baseline
**Agent task:** Reinspect current HEAD; document actual navigation, current pack counts, character reveal/refresh, settings, network calls, dependencies, release configuration, tests, and known issues. Run available Flutter analyzer, tests, and debug build; record **pass/fail with logs**. Add a short `docs/migration/BASELINE.md` and a reproducible baseline script/commands. No product refactor.
**Acceptance:** Report is sourced from current code, includes verified image counts by Topic/Pack, distinguishes observed behavior from blueprint target, and identifies any baseline test failures. Keep a rollback ref/tag without rewriting history.

### [x] T02 — GATE: Resolve implementation contracts and blueprint ambiguities
**Agent task:** Write `docs/migration/DECISIONS.md` formalizing the authoritative decisions established in the consolidated `BIGUESS_PRODUCT_BLUEPRINT.md`:
* **Canonical Card Model:** Exactly four product fields: Name, Image, Difficulty (1 = Easy, 2 = Medium, 3 = Hard), and Pack (relationship). No Subtitle, Description, Tags, Aliases, or topic-specific semantic attributes.
* **Role Permissions:** Data Collectors **cannot delete anything** (neither soft nor permanent deletion, no restoration). In MVP, deletion operations are strictly restricted to the Owner Admin. (The Moderator role is deferred to post-MVP community content, at which point Moderators will be granted soft-deletion permissions within their scope). Collectors may create, edit, upload images, assign difficulty, manage metadata, and hide content from public visibility where authorized.
* **Free vs. Pro Tier Rules:** Free users can store a maximum of **5 downloaded Packs simultaneously** (with full access to all Cards inside those Packs; removing a download frees a slot) and configure up to **10 rounds per game** (resets upon returning to Home screen without ad walls or online checks). Pro removes the 5-pack storage and 10-round per game limits.
* **Cloud Deletion & Gameplay Safety:** Cloud synchronization never interrupts active gameplay. The Game Engine runs from an immutable local content snapshot. Deletions and updates are safely applied to local storage only when returning to the Home screen or exiting gameplay.
* **Hidden vs. Deleted:** Hidden/Unpublished content is removed from catalog discovery for new downloads, but remains in storage (offline behavior for existing downloads is documented as an open decision). Deleted content creates propagating tombstones.
* **Gameplay Invariants:** Exactly one Topic per Game; one or more Packs from that Topic; cumulative difficulty 1–3; local per-device no-repeat deck; no timer/scoring/winners in MVP.
Identify and document any remaining operational/platform choices (e.g. minimum Android/iOS versions, random-Pack default count).
**Acceptance:** Shared contracts document the authoritative blueprint rules with exact section references; remaining platform/operational questions are clearly surfaced with default proposals.

### [x] T03 — Add continuous integration and fast verification
**Agent task:** Add a GitHub Actions CI workflow for Flutter dependency resolution, formatting check, static analysis, unit/widget tests, and manifest/tooling checks. Pin/document toolchain versions and use reasonable caching. Do not invoke production releases or publish artifacts.
**Acceptance:** CI runs on PR and `main`, catches a deliberate failing test/analyzer error, and documents which checks are required before merge.

**Recheck (2026-11-06):** T01/T02 verified with corrected [baseline](docs/migration/BASELINE.md), [contracts](docs/migration/DECISIONS.md), and retained command logs. T03 is complete: hosted [PR run](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/actions/runs/42199913166) and [main push run](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/actions/runs/42200303160) passed, including deliberate analyzer/test failure detection. See [CI evidence and scope](docs/migration/CI_VERIFICATION.md).

### [x] T04 — GATE: Repair Android release safety without shipping
**Agent task:** Replace debug signing for release with secure externally provided release signing configuration. Remove unsafe release-lint bypasses or add a documented, justified mitigation. Keep credentials out of Git. Audit `version.json`, release scripts, `/releases/latest` URLs, and Shorebird/version-matching behavior for draft/published version mismatches and verification of downloaded APKs. Do **not** publish a new build or change users' update path without approval.
**Acceptance:** A release build cannot silently ship signed with the debug key; local/CI validation of release configuration exists; no secrets in repository; risks and intended distribution policy are documented.

### [x] T05 — GATE: Make a reversible content inventory and rights quarantine
**Agent task:** Add a deterministic inventory/export command for all current Topic/Pack images with source path, proposed stable ID, display name, size/hash, duplicate candidates, and optional rights/source/attribution fields. Separate **technical importability** from **permission to publish**. Create a small, internally authored or otherwise confirmed-cleared fixture Pack for automated tests; do not assume Anime images or flags are public-domain assets.
**Acceptance:** Counts reconcile to source files, exports are reproducible, no asset is deleted/renamed, uncertain rights are flagged `unverified` and excluded from public test publishing by default.

**Recheck (2026-11-06):** Reversible content inventory and rights quarantine gate implemented in `scripts/content_inventory.py` with reproducible JSON and report outputs (`docs/migration/content_inventory.json` and `docs/migration/CONTENT_INVENTORY_AND_RIGHTS.md`). All 1174 source assets (922 Anime across 6 packs + 252 Flags) reconcile 100% to disk, 0 corruptions, zero assets modified/deleted/renamed, with deterministic RFC 4122 UUIDv5 stable entity IDs. Technical importability is strictly decoupled from permission to publish; all 1174 legacy assets are quarantined as `unverified` and excluded from public test publishing by default. Confirmed-cleared test fixture pack created in `test/fixtures/cleared_shapes` (4 shapes, difficulties 1–3, CC0-1.0/MIT). Verified with 7 Python unit tests and Flutter unit tests.

**Fix verification (2026-11-06):** Fixture-directory selection no longer grants clearance. The Pack and matching Card must explicitly declare clearance and provenance; absent, malformed, duplicate, unverified, or undeclared metadata remains quarantined. All 12 inventory tests pass, including the legacy-directory bypass regression; regenerated inventory preserves declared provenance.

# PHASE B — Local-first domain and playable engine (still works without a backend)

### [x] T06 — Implement canonical Topic, Pack, Card, and Difficulty domain models
**Agent task:** Add stable-identifier, topic-agnostic immutable domain models and validations: Topic ID/name, Pack ID/topic ID/name, Card ID/pack ID/name/image reference/difficulty. Adhere strictly to the canonical MVP Card model (Name, Image, Difficulty, Pack relationship); do not add Subtitle, Description, Tags, Aliases, or topic-specific attributes. Include minimal operational metadata (published/deleted/revision) outside the game-domain Card where appropriate. Publishing applies at Topic and Pack levels, not per-Card.
**Acceptance:** Serialization/validation tests cover invalid IDs/relations, difficulty outside 1–3, minimum playable Pack (2 Cards), and deterministic model equality without extra unrequested Card fields.

### [x] T07 — Introduce content repository interfaces and a legacy manifest adapter
**Agent task:** Add interfaces for reading Topics, Packs, and Cards, and implement an adapter over current `TopicPackDataSource` / `assets_manifest.dart`. Make screens/providers consume interfaces rather than direct manifest map lookups. Retain the existing Topic/Pack visual design and current game behavior temporarily.
**Acceptance:** The current two-topic/seven-pack navigation still works and tests pass; data source swapping needs no screen rewrite.

**Implemented and rechecked (2026-11-06):** `ContentRepository` exposes local Topic/Pack/Card reads, and `LegacyManifestContentRepository` adapts bundled data without changing order, labels, or image paths. Providers now resolve through `contentRepositoryProvider`; screens and the current countdown/reveal flow retain their existing contracts. Unit and widget tests cover both topics, all seven Packs, empty lookups, stable IDs, and replacement content driving navigation and reveal through one repository override. Keep the legacy adapter until the T47 retirement gate.

### [x] T08 — Add local SQLite schema, migrations, and repository implementation
**Agent task:** Add a local SQL implementation for Topics, Packs, Cards, installed-pack state, revisions, and deletion markers. Define safe schema migrations and query indexes for local search and card selection. Keep mutable active game state out of the database unless required by the blueprint.
**Acceptance:** Integration tests create/open/upgrade/restart the database; relationships and constraints are enforced; local queries work without network; no bundled asset loss.

**Implemented and rechecked (2026-11-06):** [Local storage contract](docs/migration/LOCAL_CONTENT_STORAGE.md), `ContentDatabase`, and `SqliteContentRepository` provide versioned native SQLite storage. Schema v3 keeps installed Card snapshots independent of newer cached metadata; installed revision and snapshot replacement commit atomically. Regression tests cover cached updates, restart, retry, activation failure, and v1/v2 upgrades. Ambiguous older databases fail upgrade without data loss rather than relabeling newer Cards as installed. The bundled gameplay provider remains the default.

### [x] T09 — Define a deterministic Pack format and local test Pack exporter
**Agent task:** Specify an initial full-Pack manifest containing Pack/Topic IDs, revision, Card metadata, image object references, sizes, and SHA-256 hashes. Implement an offline exporter for verified test fixtures (and a development-only export path for legacy assets). Do not start with a network client.
**Acceptance:** Identical input produces equivalent manifest/output hashes; malformed/duplicate/missing records fail validation; a complete Pack has all assets necessary for offline play.

**Implemented:** [Full-Pack v1 contract and commands](docs/migration/PACK_FORMAT.md), offline `scripts/export_pack.py`, and self-contained acceptance tests in `.agents/tests/test_pack_export.py`. Fixture exports require explicit clearance; legacy exports require development-only opt-in. Import/install remains T10.

### [x] T10 — Implement atomic local Pack import/install from a file
**Agent task:** Parse and validate Pack files, stage them in a temporary location, confirm image hashes/sizes and referential integrity, then atomically activate metadata and files. Preserve previous installed data if validation or storage fails; make install retry-safe.
**Acceptance:** Valid fixture Pack installs and survives app restart; malformed, partial, and tampered Packs are rejected without damaging the previous playable Pack.

**Implemented:** `LocalPackStore` validates T09 `.biguesspack` files, stages and verifies images/metadata in private storage, then activates an immutable generation with one atomic pointer rename. Reopening and retry/rollback tests cover malformed, partial, tampered, and storage-failure cases. See [installation API and guarantees](docs/migration/LOCAL_PACK_INSTALL.md). The legacy gameplay path remains playable during migration.

### [x] T11 — Implement private local image storage and a presentation-safe image loader
**Agent task:** Add an abstraction for asset images (legacy) and locally installed protected Pack images. Use app-private storage and practical protection/packaging, not public gallery paths. Benchmark/limit decoding overhead and caching; avoid claiming perfect DRM.
**Acceptance:** Locally installed images render correctly offline, no public-gallery pollution, bounded memory for larger Packs, and legacy images still render during migration.

**Implemented:** `LocalPackStore` packages new images in app-private containers, and `ContentImageLoader` resolves both bundled assets and installed images without extracting plaintext files. Older loose private generations remain readable. Decodes fit within 1024×1024; the retained image cache is limited to 32 MiB/32 entries, with two sequential warmup images. Offline pixel/render tests, corruption/retry and storage tests, and a 48-image cache/decoding workload verify the behavior. See [protection limits and benchmark evidence](docs/migration/PRIVATE_IMAGES.md); packaging is not encryption or perfect DRM.

### [x] T12 — Extract a pure non-repeating Card selection engine
**Agent task:** Replace image-path-based selection in the **new** domain path with a pure shuffled local deck of Card IDs; apply cumulative difficulty, exclude duplicates until exhausted, reshuffle after exhaustion, and allow separate physical devices to select the same Card. Keep the legacy controller working until UI migration.
**Acceptance:** Deterministic seeded tests cover difficulty, 0/1/N eligible cards, pool exhaustion, multiple Packs, duplicate IDs, and device-independent sessions.

**Implemented:** `CardSelectionEngine` captures unique eligible Card IDs from the supplied local Packs, defaults to Easy, and draws from a shuffled deck without replacement. Empty pools return null; exhausted decks reshuffle from the captured IDs. Seeded tests cover the acceptance cases, reproducibility, shared image/name references, and isolation from later input mutations. Each instance owns its draw history; matching Cards on separate devices and repeats across exhausted deck boundaries are allowed. The legacy `GameRoundNotifier` / `SelectCharacterUseCase` path remains in place until UI migration.

### [x] T13 — Implement the local GameSession state machine
**Agent task:** Model configuration, start, active round index, assigned Card, Next Round, completion, exit, and replay routing. Game state remains temporary/in-memory. Use an immutable snapshot of selected installed content for a running game; no scores, winners, questions, rooms, or authentication. Ensure an active game in progress is never invalidated, modified, or interrupted by remote updates, deletions, or unpublishing. For Free games, completing the final round completes the session; restarting another game requires routing through the Home screen to reset the 10-round counter. Direct 1-tap in-session replay without returning to Home is a Pro capability.
**Acceptance:** Unit tests prove exact number of rounds, transitions, safe exit, round-limit reset on return to Home, and complete isolation of the active game snapshot against background content updates or deletions.

**Implemented:** [Local GameSession contract](docs/migration/GAME_SESSION.md), immutable `GameSessionConfiguration` / `GameContentSnapshot` / `GameSession`, and `gameSessionProvider` model setup, assigned Cards, exact round completion, safe exit and replay routing entirely in memory. Free replay requests Home without resetting until Home is reached; Pro replay immediately reuses the frozen configuration/content. Thirty unit/integration tests cover transitions, Free counts 1–10, Pro counts above ten, Home reset, provider/input isolation, SQLite updates/unpublishing/tombstones and retained image-generation bytes after Pack replacement. T13-only checkout verification passes all 171 Flutter tests, analysis and tooling checks; UI migration remains T16/T17.

### [x] T14 — Build the Game Configuration UI with validation
**Agent task:** Add a short setup step after Pack selection for cumulative Difficulty (Easy default) and number of rounds. Enforce the Free-tier limit of up to **10 rounds per game**. Freeze settings on Start; validate nonempty eligible pools and at least one downloaded Pack.
* **MVP Entitlement Decision:** Production builds default strictly to the Free-tier rules (5 stored packs max, 10 rounds max per game). To allow automated tests and manual QA of Pro features (unlimited packs, unrestricted rounds) without premature commercial billing or payment gateway dependencies, provide a defined internal Entitlement Provider with a debug/test toggle or environment configuration (`isProTestEnabled`). Store billing, commercial In-App Purchases, and receipt validation remain deferred to post-MVP (F01).
**Acceptance:** Invalid combinations cannot start, settings do not mutate mid-game, Free round configuration enforces max 10 rounds by default, internal Pro test toggle unblocks unrestricted rounds, and widget tests cover defaults and navigation.

**Implemented:** [Game setup and internal QA access](docs/migration/GAME_SETUP.md) adds cumulative Difficulty (Easy default), round entry (10 default), installed-content/pool validation and an immutable Start snapshot. Free defaults enforce 10 rounds and 5 stored imported Packs; the non-release `isProTestEnabled` define/provider override removes both limits. Configured legacy reveals stop at the requested count and return through Packs; full session/completion UI remains T16/T17. Widget, domain, repository and installer tests cover defaults, navigation, frozen settings/content, invalid combinations, Pro access and concurrent storage limits.

### [x] T15 — Extend Pack selection to single, multiple, and random within one Topic
**Agent task:** Evolve `PacksScreen` selection without cross-Topic mixes. Random mode draws only from locally available playable Packs; clearly surface download-required and unavailable Packs. Use consistent IDs rather than display names for persisted selection.
**Acceptance:** Tests verify all three modes, single-topic invariant, no eligible/random Pack case, and correct merged Card pool.

**Implemented:** `PacksScreen` retains selection by Topic/Pack IDs, supports single/multiple/random selection, and labels download-required and unavailable Packs. Random count starts at one and is adjustable within the locally playable pool. Selection validates installed snapshots and merges all selected Cards before setup; setup rechecks availability at Start and freezes the chosen IDs. Unit, SQLite, and widget tests cover all modes, Topic isolation, empty random pools, renamed labels, merged content, and local removal during setup or gameplay.

### [x] T16 — Migrate the Identity Screen to the new GameSession and local images
**Agent task:** Reuse current theme, animations, and widgets while migrating the Identity Screen to the new GameSession and local images. The removal or simplification of the existing Mystery Box tap, countdown animation, and related UI controls is a **design proposal subject to human product/UX approval** during this ticket; if preferred, the playful reveal animation can be retained in a faster, more responsive form. Ensure the outward-facing Card shows its identity name and image reliably. Keep motion purposeful and fast.
**Acceptance:** Widget tests verify identity display after game start; no timer or per-question UI; UX transitions (whether immediate display or playful reveal) receive explicit sign-off; loading, missing image, orientation, accessibility, and accidental-tap behavior are handled.

**Implemented:** [Identity screen and explicit UX sign-off](docs/migration/IDENTITY_SCREEN.md). On 2026-11-06 the user approved immediate reveal after Start, with a 250 ms entrance and no motion when reduced motion is enabled. Configured games render the session-assigned Card's canonical name and local image through the existing themed Card widget. Names stay visible and image/name taps are inert; session settings omit legacy countdown, algorithm and hint controls. Ten focused widget tests cover Start, shared-image Card identities, local private image pixels, loading/errors, orientation, large text, semantics, reduced motion and duplicate action dispatch. The legacy reveal remains available during migration.

### [x] T17 — Add game-complete and replay flow
**Agent task:** Display `Round X of Y`, a clean completion state after the configured final round (up to 10 in Free).
* **Free Version Replay Flow:** Free players must return to the Home screen (or Packs screen) before starting another game. The primary completion action is `Return to Home` (or `Play Again`, which explicitly routes back through Home to reset the 10-round counter for a new game with zero advertisements, paywalls, or network requirements). Free mode does NOT provide an immediate in-session Replay action that bypasses Home.
* **Pro Version Replay Flow:** Pro users (and Pro-test enabled builds) have an immediate `Replay` button to restart a new session instantly using the exact same configuration without returning to Home.
Do not infer or display a digital winner.
**Acceptance:** UI tests verify final round completion; in Free mode, completing configured rounds requires returning to Home to reset the counter; Pro mode allows direct instant replay; default path is faster than the old repeated countdown flow.

**Implemented:** Configured games now use the local `GameSession` engine, display `Round X of Y`, and advance immediately from Start through Next Round without repeated countdowns. Finish Game completes the final displayed round without drawing another Card. Free completion returns through Packs before a fresh game resets the counter; Pro/test replay instantly reuses the exact frozen configuration and content. Widget tests cover 1/3/10-round Free sessions, Pro replay above ten rounds, changed content/access rules, stale taps, Back, hint reset, and compact completion layout. T16 identity-screen UX sign-off remains separate.

### [x] T18 — GATE: Prove entirely offline local-Pack gameplay
**Agent task:** Wire game screens to the local SQL/content repository with an imported fixture Pack. Disable connectivity, kill/restart the app, and prove Topic → Pack → Config → Card → all rounds works without any API/auth/image requests. Preserve a functioning legacy fallback until the subsequent cloud path is verified.
**Acceptance:** Repeatable automated/instrumented or documented manual offline test passes; no network dependency or database corruption; developer can demo it without cloud infrastructure.

**Implemented and verified (2026-11-06):** Startup binds verified imported generations to a separate transactional SQLite projection; empty/error storage retains the bundled fallback and an explicit legacy rollback switch. Local-Pack navigation suppresses automatic update requests. The [offline gate and Android demo](docs/migration/OFFLINE_GAMEPLAY_GATE.md) include a repeatable network-namespace runner: it SIGKILLs the actual Flutter test app during a rendered round, removes the import source, then restarts against the same storage and completes ten plus three rounds with private images, canonical names, zero HTTP-client attempts, and passing SQL integrity/foreign-key checks. [Execution evidence](docs/migration/evidence/2026-11-06-t18/summary.json) records the host-engine result; physical-device and published OTA-engine validation are not claimed. T16 UX sign-off and subsequent cloud-path verification remain separate gates.

# PHASE C — Shared content API and cloud foundation

### [x] T19 — Freeze versioned catalog, Pack, and sync API contracts
**Agent task:** Define JSON schemas/OpenAPI for public catalog, Pack manifest, initial download, delta changes, revisions, tombstones, errors, and Studio mutations. Include stable IDs, pagination, ETags/revision checks, content hashes, and explicit protocol compatibility rules. No backend deployment required yet.
**Acceptance:** Contract tests/fixtures reject incompatible payloads and can be consumed by Mobile and Studio without Flutter-specific coupling.

**Implemented:** [Frozen content protocol v1](contracts/content/v1/README.md), OpenAPI 3.1 and JSON Schema 2020-12 definitions, portable positive/negative fixtures, and `.agents/tests/test_content_contract.py`. Reuses the existing full-Pack v1 format; includes semantic relationship/revision checks and real artifact digest verification. CI installs the pinned contract tooling. No backend deployment or app network client.

### [x] T20 — Scaffold Cloudflare Workers, D1 migrations, and R2 bindings
**Agent task:** Create an isolated `backend/` project with local development, migrations, typed environment bindings, nonproduction environments, deterministic seeds, and tests. D1 stores structured data; R2 stores optimized image/content objects. Never put API secrets into Flutter code or source control.
**Acceptance:** Backend runs locally with a fixture; migrations are repeatable; no production writes required; documented deploy/rollback plan exists.

**Implemented:** [Isolated content infrastructure](backend/content-api/README.md) with typed Worker bindings, separate local/staging D1 and private R2 resources, a numbered metadata migration, deterministic WebP seeds, a locked Node toolchain, and workerd integration tests. Tests cover repeated local migrations/seeds, persisted D1/R2 reads, corrupt/missing objects, staging fixture exclusion, and seed/secret guardrails. Local HTTP smoke checks serve verified fixture bytes. Deploy/rollback is documented; no cloud resources or production writes were required. Catalog, publishing, and Studio endpoints remain subsequent tickets.

### [x] T21 — Implement public read-only catalog endpoints
**Agent task:** Serve only published Topics and published Packs belonging to visible Topics, with compact metadata, counts, revisions, pagination, caching headers, and clear unavailability responses. No gameplay-session or per-Card online endpoints.
**Acceptance:** Contract/integration tests verify unpublished content is hidden, stable ordering, cache behavior, errors, and anonymous mobile access.

**Implemented:** [Public catalog v1](backend/content-api/README.md#public-read-only-catalog), with D1 published-summary projections, snapshot-bound pagination, exact UTF-8 ID ordering, SHA-256 ETags, conditional caching, anonymous CORS, and structured availability/storage errors. Workerd/D1 integration tests validate actual responses against the frozen shared contracts and cover hidden/deleted content, stable pages, cursor binding/tampering/expiry and cache revalidation. No deployment or gameplay/Card endpoints.

### [x] T22 — Implement immutable R2 objects and signed Pack manifests
**Agent task:** Add deterministic publishing artifacts/manifests and immutable/content-addressed image keys in R2. Verify checksums and prevent half-published revisions becoming visible. Keep a previous valid revision available for rollback; access must be appropriate for public downloaded content.
**Acceptance:** A full fixture Pack can be resolved/downloaded and verified against its manifest; missing/altered objects fail safely; publishing is atomic from the catalog perspective.

**Implemented:** [Immutable publication and signature protocol](backend/content-api/PUBLISHING.md), deterministic offline Ed25519 receipts, create-only content-addressed R2 artifacts, read-back checksum verification, and a compare-and-swap D1 transaction that activates immutable history and catalog summaries together. Anonymous revision-specific manifest/receipt/archive/image routes preserve the frozen v1 payloads, verify storage before successful/conditional responses, and retain earlier revisions for forward rollback. Workerd tests cover a complete downloaded Shapes fixture, every interrupted write stage, competing publishers, catalog-transaction failure, missing/altered objects, signature trust, visibility and immutable-key collisions. No cloud deployment, public publishing mutation or Flutter download client is added.

### [ ] T23 — Enforce Studio authentication and roles at the API boundary
**Agent task:** Verify Firebase-issued Google sign-in tokens on Workers; authorize only allowlisted/data-driven Owner/Admin and Collector roles. Enforce strict permissions server-side: Owner Admin has full control; Data Collectors may create/edit Packs and Cards and manage permitted metadata, but **Data Collectors cannot delete anything** (neither soft nor permanent deletion). In MVP, deletion endpoints are strictly restricted to the Owner Admin. Moderator and community roles are explicitly post-MVP. Players remain accountless.
**Acceptance:** Automated tests cover unauthenticated, unauthorized, Collector, and Owner requests; verify server-side rejection if a Collector attempts any deletion or restoration operation; user tokens cannot elevate roles; credentials are server-side.

### [ ] T24 — Implement versioned administrative mutations, soft deletion, and audit records
**Agent task:** Add authenticated Topic/Pack/Card create/edit/batch APIs, optimistic revision/conflict checks, Owner Admin soft-deletion and Owner-only restore/permanent-delete paths (Moderator role is post-MVP), and concise audit attribution. Enforce that Collectors can create, edit, and hide content, but cannot invoke soft-deletion or permanent deletion endpoints. Design mutations around Studio batches, not every keystroke.
**Acceptance:** Concurrent invalid revisions are rejected clearly; permission tests verify Collectors cannot delete content while Owner Admin can; relationships remain valid, and deletion creates audit records and tombstones.

### [ ] T25 — Implement Pack revisions, delta metadata, and deletion tombstones
**Agent task:** Produce monotonic Pack revisions and change sets for added/edited/hidden Cards and replaced images; issue tombstones for administratively deleted Packs so connected devices discover deletion even if catalog entries disappear. Enforce automated validation rules before a published revision is distributed. Treat Pack as initial download unit, individual changes as update transport.
**Acceptance:** Tests for unchanged, new Card, edited Card, changed image, hidden Card, deleted Pack tombstone; validation blocks distribution of invalid revisions; delta traffic excludes unchanged bytes.

# PHASE D — BiGuess Studio (trusted contributors only)

### [ ] T26 — Scaffold a separate Flutter Studio application
**Agent task:** Create a maintainable Studio app/workspace without relocating or rewriting the existing Flutter Mobile app unnecessarily. Share only stable domain/contracts. Add Studio test/build scripts, routing, theme, login shell, and empty-state navigation.
**Acceptance:** Studio runs independently; Mobile still builds; no duplicated provider-specific business logic.

### [ ] T27 — Add Studio Google sign-in, authorization, and role-based UI
**Agent task:** Integrate Firebase Auth, session handling, authorized-user lookup, Owner/Collector gating, logout, and unauthorized/expired-session handling. UI gating complements — never substitutes for — Workers enforcement.
**Acceptance:** A non-allowlisted account cannot access Studio; user role is server-derived; tests cover login states and permission-dependent actions.

### [ ] T28 — Implement Studio local-first dataset and initial sync
**Agent task:** Persist Topics/Packs/Cards locally after first authorized login and allow reading/editing cached working data temporarily offline. Define a pending-change queue, safe retry, and schema/version handling compatible with the chosen Studio target platform. Do not introduce realtime listeners.
**Acceptance:** First login hydrates local dataset; relaunch/offline reopening works; unsent edits are retained and distinguishable from published server state.

### [ ] T29 — Implement Owner Topic CRUD, list, search, and filters
**Agent task:** Build Topic create/rename/archive-or-delete actions under the documented Owner permission. Read from local Studio state and queue changes for explicit commit. Show draft/published/removed status appropriately.
**Acceptance:** CRUD and filter tests; Collectors cannot perform Owner-only Topic operations; no per-keystroke backend writes.

### [ ] T30 — Implement Pack Operations, restoration, and status UI
**Agent task:** Build Pack create/edit, association with a single Topic, and list/search filtering. Respect role boundaries: Collectors can create, edit, and hide Packs; in MVP, soft-deletion, restoration, and permanent deletion are restricted to Owner Admin (Moderator role is post-MVP). Implement precise UI confirmation for destructive administrative actions and show last-synced vs pending status.
**Acceptance:** Cannot create orphan Packs or inadvertently purge existing content; role tests verify Collectors cannot trigger deletion; offline queued changes survive restart.

### [ ] T31 — Implement Card operations, difficulty, names, and image replacement
**Agent task:** Add Card creation, editing, and hiding for Collectors; in MVP, deletion is strictly restricted to Owner Admin (Moderator role is post-MVP). Maintain canonical Card fields (Name, Image, Difficulty 1–3, Pack relationship); do not add Subtitle, Description, Tags, or Aliases. Implement optional filename-to-name suggestion, image reference editing, and per-Card review. Keep Card topic-agnostic; publishing remains at Topic/Pack level.
**Acceptance:** Invalid Cards cannot be committed/published; changing an image leaves the Card identity stable; Collectors cannot delete Cards; Card count/update tests pass.

### [ ] T32 — Implement automated image normalization and validation
**Agent task:** Port/reuse current Python optimization concepts in Studio's upload pipeline: decode/resize, WebP compression, remove unwanted metadata, normalize names, hash/deduplicate, and validate corrupted images. Treat normally below 50 KB/image and generally below 10 MB/Pack as optimization targets rather than rigid rejection caps that would degrade quality.
**Acceptance:** Fixtures test PNG/JPEG/WebP, bad inputs, duplicate imports, output size, transparency, and visual/image metadata preservation where needed.

### [ ] T33 — Implement bulk Card/image import with review before commit
**Agent task:** Select many images, generate a pending Card table, edit names and difficulties per item, apply role-appropriate bulk actions (Collectors can bulk-edit difficulty, move within scope, or hide; bulk deletion is Owner Admin only in MVP), inspect duplicates/invalid rows, and commit a validated batch. Do not automatically publish newly imported content.
**Acceptance:** Hundreds of fixture Cards can be imported without one network write per row; cancellation leaves published data unchanged; clear per-row errors; Collectors cannot bulk-delete.

### [ ] T34 — Add local search/filtering, content status, and duplicate detection
**Agent task:** Implement fast search by Topic/Pack/Card names and filters for difficulty, status, missing images, and duplicates. Surface validation warnings and distinguish technically duplicated bytes from semantically duplicated identities.
**Acceptance:** Works across thousands of Cards in cached data, including offline; benchmark and test meaningful search/filter cases.

### [ ] T35 — GATE: Implement deliberate Topic/Pack publishing, automated validation, and rights checks
**Agent task:** Add preview/review/validate/publish/unpublish workflow. Initial publication of Topics and Packs requires Owner Admin approval. Routine maintenance of published Packs by authorized Collectors (adding, editing, or hiding Cards) proceeds without Owner approval bottlenecks, but **must pass automated validation rules** before a new revision is distributed. Packs require >=2 eligible valid Cards and complete images. Add rights-approval status at the publishing boundary, but do not treat a disclaimer as legal clearance.
**Acceptance:** Invalid, missing-image, orphaned, unpublished, or rights-unapproved content cannot reach the public catalog; automated validation blocks distribution of invalid revisions; approved publishing creates a complete immutable revision; no independent Card publishing.

### [ ] T36 — Implement explicit commit, manual refresh, and incremental Studio sync
**Agent task:** Turn queued local edits into authenticated batched commits. Manual Refresh first checks lightweight revisions then pulls deltas and deletion markers; no polling, realtime listeners, or typing-time writes. Handle stale-edit conflicts conservatively and show user-resolvable errors without building advanced collaborative editing.
**Acceptance:** Offline edit → reconnect → commit → refresh works; unchanged refresh transfers minimal data; two stale clients cannot silently overwrite one another.

### [ ] T37 — Add trusted contributor profile and basic contribution statistics
**Agent task:** Display signed-in user, role, and backend-derived counts of approved additions/removals for Topics/Packs/Cards. No XP, rankings, badges, or public contributor accounts.
**Acceptance:** Counts derive from validated server activity/audit records, not user-editable local counters; role/privacy tests pass.

### [ ] T38 — GATE: Reproducibly import legacy content into Studio as nonpublic drafts
**Agent task:** Run the T05 inventory through T06 models, T32 image processing, and Studio imports. Preserve source-to-new-ID mappings, names, hashes, and before/after counts. Use **draft/unpublished quarantine** for uncertain IP, while importing only explicitly cleared fixtures to a publicly testable environment. Preserve original source and reversible reports.
**Acceptance:** Expected 922 Anime + 252 Flags source files are accounted for (or every difference explained), import is idempotent, referential integrity passes, and no unapproved assets are exposed publicly.

# PHASE E — Connect Mobile to remote content distribution

### [ ] T39 — Add a remote catalog repository and offline-aware browsing UI
**Agent task:** Reuse `TopicsScreen`/`PacksScreen`, now backed by the public versioned catalog plus cached local summary. Display Pack names, descriptions/counts, downloaded and update status, and clear offline/no-connection conditions. Avoid network on every screen rebuild.
**Acceptance:** Anonymous catalog browsing works online; already cached local Pack metadata still renders offline; old manifest adapter can remain behind a migration flag.

### [ ] T40 — Implement resumable full-Pack download and integrity verification
**Agent task:** Build an HTTP download service driven by Pack manifest/revision with checksums, safe temporary files, timeouts, progress, retry behavior, and a local Pack state machine (`NOT_DOWNLOADED`, `DOWNLOADING`, `AVAILABLE`, `UPDATE_AVAILABLE`, `UPDATING`, `FAILED`). Never mark content playable before verification.
**Acceptance:** A full cleared fixture Pack downloads, installs, survives app restart, and fails safely on hash mismatch, bad network, and missing objects.

### [ ] T41 — Add atomic activation, interruption handling, and download concurrency limits
**Agent task:** Ensure partial downloads/updates cannot damage installed Packs; resume or restart safely after force-close/network loss; cap parallel downloads and check space before allocation; allow manual cancellation and retry. Protect current active-game content snapshots.
**Acceptance:** Kill/relaunch/interrupted update tests keep prior Pack playable; no orphan temporary files accumulate; storage-full state is recoverable.

### [ ] T42 — Route Mobile gameplay exclusively through installed local Packs
**Agent task:** Switch the main flow to installed local Cards/images only; block gameplay for not-downloaded Packs with a clear Download action. Enforce the Free-tier storage rule: **maximum 5 downloaded Packs stored simultaneously** (all Cards inside downloaded Packs accessible). If 5 Packs are already stored, downloading another requires removing an existing download to free a slot. Wire into the MVP Entitlement Provider (Free by default; test toggle enables Pro unlimited storage). Confirm zero gameplay API, image request, authentication, or server dependency after Start. The game loop must work in airplane mode.
**Acceptance:** End-to-end on-device test with downloaded fixture content passes through all rounds offline; Free 5-pack storage slot constraint is enforced with clear slot-freeing UI; backend outage does not block existing content; no manifest fallback is needed for the new path.

### [ ] T43 — Implement incremental Card/image Pack updates and manual refresh
**Agent task:** Check lightweight revisions/ETags and fetch only missing/changed records and images. Stage updates atomically, preserve unchanged assets, and activate new revision only for future games. Avoid continuous polling; expose Update Available and a manual action.
**Acceptance:** Tests demonstrate 100→105 Cards downloads only five new Cards plus relevant metadata/images, no unnecessary redownload for unchanged Pack, and correct handling of changed image content.

### [ ] T44 — Implement cloud deletion synchronization and local storage management
**Agent task:** Distinguish a user's local Remove Download (redownloadable when published, frees a storage slot) from an authoritative cloud tombstone (delete local copy after next valid sync). Enforce the **gameplay non-interruption rule**: when synchronization detects a deletion, an active game continues using its local snapshot without interruption; deletion is safely applied to local storage only when the player returns to the Home screen or exits gameplay. Provide user-facing storage management; never attempt to control a disconnected offline device.
**Acceptance:** Online tombstone clears local Pack safely after exiting gameplay; offline device can use installed Pack until it reconnects; local removal frees a slot while leaving server content intact; no mid-round interruptions or orphaned images.

### [ ] T45 — Remove automatic startup update dependency without breaking safe app updates
**Agent task:** Reconcile current `TopicsScreen` silent check/mandatory modal, `UpdateController`, Shorebird, APK installer, and the blueprint's no-network-to-play principle. Keep app updates separate from Pack content updates. Prefer a clearly optional settings/about update path and protect already downloaded gameplay from remote version service outages; any mandatory upgrade policy requires explicit product approval.
**Acceptance:** Airplane-mode launch with downloaded content proceeds without update delay/dialog; update UI cannot block normal play solely because its server is offline; obsolete update plumbing is removed only after a tested replacement policy exists.

# PHASE F — Validate, migrate, and prepare a controlled MVP release

### [ ] T46 — GATE: Run the full content/offline synchronization test matrix
**Agent task:** Add integration tests (and a reproducible physical-device checklist) for new Pack, unchanged Pack, new/edited/deleted Card, changed image, remote Pack deletion, offline restart, interrupted install, repeated refresh, backend outage, multiple Packs, local removal/reinstall, and snapshot during active rounds. Include malformed/malicious manifest and unauthorized Studio action tests.
**Acceptance:** Every required scenario from blueprint **Migration §25** is recorded with pass/fail and evidence; no internet is needed from Start Game until completion.

### [ ] T47 — GATE: Retire legacy hardcoded content and clean up safely
**Agent task:** Only after T46 passes, remove production gameplay dependence on `assets_manifest.dart` and bundled Anime/Flags files; shrink the app without deleting source archives needed for rollback. Clean `old-lib/`, `old-test/`, stale scripts, unused dependencies, and outdated documentation deliberately. Update README truthfully to the shipped capabilities and reconcile version metadata; no destructive Git-history rewrite by default.
**Acceptance:** App builds/runs with cloud-distributed downloaded Packs, migration reports confirm asset coverage, old code has no remaining references, rollback artifacts exist, and release APK size is measured.

### [ ] T48 — GATE: Release hardening, operational limits, and rollback drill
**Agent task:** Add backend observability and budgets/usage alerts for Workers, D1, R2; secure operational access; test D1 backup/restore, R2 object retention, schema rollback, and app rollback. Validate Android signing and release artifacts; ensure production Studio roles, rights approval, legal notices, and content takedown procedures are reviewed by the owner/legal counsel. Do not deploy automatically.
**Acceptance:** Release checklist has owners, evidence, cost ceilings, rollback steps, privacy/security review, and a single approved staging→production promotion procedure.

### [ ] T49 — GATE: Run realistic playtests and sign off MVP
**Agent task:** Set up instrumented or consent-based observational playtests with two-plus people and real, rights-cleared, varied Packs. Check time-to-first-game, identity display readability when phones face outward, ease of Next Round, failed downloads, clarity of Pack states, and desire to replay; fix only release-blocking problems in scoped follow-up tickets.
**Acceptance:** Document observations, blocker fixes, offline repeat tests, and the final **MVP definition of done**. Product demand is assessed separately from technical completion.

---

## Human decisions / non-coding gates that an agent cannot resolve

1. **Content rights and distribution:** The software can track rights and block publication, but only a rights holder/licensor or qualified legal review can authorize a use. The current Anime assets must not automatically become public downloadable/cloud assets because they existed in the old APK/repo.
2. **MVP defaults:** Approve round-count UI defaults (up to 10 in Free; unrestricted in Pro), Random Pack semantics within Topic, supported target devices, and where Studio is deployed. (The canonical Card model is decided: Name, Image, Difficulty 1–3, Pack relationship).
3. **Release distribution:** Choose direct APK, store, Shorebird strategy, and mandatory-update policy before replacing existing production update mechanisms or releasing builds.
4. **Monetization & Free/Pro Model:** The blueprint establishes an explicit freemium model: Free users can store up to **5 downloaded Packs simultaneously** (with full access to all Cards inside those Packs) and configure up to **10 rounds per game** (resets from Home screen without ads or online requirements). Pro removes the 5-pack storage and 10-round limits. Monetization should not interrupt active gameplay or enforce online DRM during offline play. Do not put unlicensed franchise content behind a paywall.
5. **Legal takedowns:** Deletion tombstones can remove downloads only when a device eventually syncs; they cannot remotely erase content from disconnected devices or undo already redistributed copies.

## Explicitly deferred, post-MVP backlog — do not assign until real demand exists

- **F01:** Free vs Pro payment gateway, billing integration, and entitlement management (following the established 5-pack storage and 10-round per game Free model vs unrestricted Pro), after legal/commercial review and user-demand evidence.
- **F02:** Billing and entitlement restoration that do not require per-round internet checks.
- **F03:** Public creator accounts, submission and moderation queue, rights verification, abuse reporting, takedown tooling.
- **F04:** Creator contributions, public reputation and marketplace — only after moderation, payments, taxation, and licensing are viable.
- **F05:** Fully licensed/owned partner content and custom event Packs.
- **F06:** Advanced analytics/experiments after basic retention is measured privacy-consciously.
- **F07:** Revisit timer, AI, scores, matchmaking, realtime play only on demonstrated need; these explicitly contradict the current lean MVP scope unless consciously approved as a new product direction.

## First message to give the coding agent

> **BiGuess ticket T01 — Freeze the behavioral baseline.** Work against the current `main` branch of `AbderrahmaneSAOUDI/BiGuess-Game`. Read `BIGUESS_PRODUCT_BLUEPRINT.md` (especially *Migration Plan From Current BiGuess*) and inspect the current source and relevant history. Run the actual Flutter analyzer, tests, and a debug build; document pass/fail without claiming success for commands you did not execute. Inventory Topics/Packs/images from source, trace current user flows, startup network requests, gameplay controller, dependencies, release-signing setup, and migration risks. Add `docs/migration/BASELINE.md` plus any minimal reproducible audit script. **Do not refactor gameplay, migrate assets, change release distribution, publish content, or start T02.** Deliver a reviewable PR, changed-file list, test logs, discovered discrepancies, and recommendations for the next ticket.

### Evidence links

- [Current repository](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game)
- [Current baseline commit](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/commit/d4ab660faacd1c4f923278456b29f58755ae7040)
- [Topic/Pack asset refactor](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/commit/d988235ee0cce1496addef90d9155f4761a8ff8b)
- [Version/OTA reintroduction](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/commit/c78c652ba01ac6dcc4c9d3e6a2b008fdd3014df8)
- [Current blueprint](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/blob/main/BIGUESS_PRODUCT_BLUEPRINT.md)
- [Manifest-backed content data source](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/blob/main/lib/data/datasources/topic_pack_data_source.dart)
- [Current game controller](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/blob/main/lib/providers/game_controller.dart)
- [Current Android build configuration](https://github.com/AbderrahmaneSAOUDI/BiGuess-Game/blob/main/android/app/build.gradle.kts)

*Audit scope note:* This roadmap reflects the retrieved `main` source, tree, history and attached blueprint as of the date above. The repo may advance; every ticket should verify the current branch before work. Test/build commands were not executed in this audit. No repository files, issues or releases were changed by preparing this roadmap.
