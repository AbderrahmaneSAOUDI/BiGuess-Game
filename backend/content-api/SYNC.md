# Pack revisions, deltas and deletion discovery (T25)

Apply additive `0005_distribution.sql` after the existing migrations through the
local migration workflow. No remote migration, Worker deployment or Mobile
network client is included. The [frozen v1 protocol](../../contracts/content/v1/README.md)
remains unchanged.

## Installed Pack revision checks

Anonymous `POST /content/v1/sync/revisions` accepts a JSON body:

```json
{"protocolVersion":1,"packs":[{"packId":"shapes","revision":1}]}
```

Submit 1–100 distinct IDs with positive safe integer revisions, at most 64 KiB,
without extra fields or query parameters. The response contains exactly one
result per submitted ID, in input order, with `Cache-Control: no-store`:

- `unchanged`: the same published revision, with its manifest SHA-256.
- `updateAvailable`: a higher published revision and manifest SHA-256.
- `unavailable`: hidden/unpublished content or ancestor; this never authorizes
  local deletion.
- `deleted`: a **newer** retained Pack tombstone, UTC deletion time, and
  `reason: administrative_deletion`.
- `unknown`: no known identity/publication/deletion evidence; this never
  authorizes local deletion.

The query starts from installed IDs, not catalog rows. Deletion therefore remains
discoverable after catalog removal, permanent product-field purge, or catalog
pagination expiry. Topic deletion creates explicit descendant Pack tombstones.
Tombstones are retained indefinitely. A client older than a retained deletion
still receives that evidence after restore or later publication; a new download
uses the later approved revision. Restore does not erase evidence or republish.

A known revision ahead of server state returns 409 `revision_conflict` for the
whole request. A deleted Pack never returns a tombstone at or below the installed
revision: that impossible deletion state also returns a conflict. No response
silently downgrades a visible published revision. Draft revisions are not
advertised as available updates. Published statuses verify receipt signatures,
identity and the catalog hash using D1 metadata and pinned keys, with **no R2
image/archive reads**. Public CORS supports anonymous JSON POST preflight.

## Exact revision deltas

Anonymous `GET /content/v1/packs/{packId}/delta?fromRevision=A&toRevision=B`
requires exact positive integers with A < B. It compares two immutable validated
full manifests and returns the frozen `Delta`:

- Full Card records in `upsertCards` for added or edited identities, including
  changed names, difficulty or image references.
- `removeCardIds` for Cards absent from the target, including hidden/deleted
  Cards. A Card cannot occur in both lists.
- `objects` containing only target image descriptors required by upserts whose
  keys are absent from the base manifest. Existing shared images are reused.
- The exact target full manifest hash and revision-specific manifest URL.

Metadata-only/unchanged-content publications have empty change arrays. Images
are not embedded, and no archive is transferred by the delta route. Fetch only
missing verified content-addressed objects relative to the target manifest URL;
the same image shared by many Cards appears once. The full Pack archive remains
the **initial download unit** and the fallback when history is unavailable.

Missing retained revision metadata returns 409 `delta_unavailable`: resolve a
fresh full-Pack download rather than applying an incomplete patch. Hidden
content returns 403, deleted content 410, unknown Packs 404, malformed ranges
400, and damaged/untrusted stored artifacts 503. All errors are `no-store`.
Successful deltas use exact-byte SHA-256 ETags, anonymous CORS, and
`public, max-age=60, must-revalidate`. Visibility and complete target validation
run before 304 handling as well as before 200 responses.

The receiver must fetch/verify the target manifest, reconstruct its exact Card
and required-object sets, and stage one atomic installation. Keep active gameplay
and its image snapshot independent; applying updates/deletions only at a safe
local point belongs to the Mobile integration tickets. There is no polling,
realtime listener or account requirement for players.

## Validation and monotonic publication

Studio commits and trusted publications now share an administrative generation
guard in D1. A publication cannot overwrite a competing edit, delete/restore,
newer draft revision or permanent identity fence. New publications initialize
Studio authoring records; old catalog-only fences can hydrate Cards from the
verified previous manifest during publication. Missing/removed Card identities
are retained rather than reused in another Pack.

A pending administrative snapshot must be published at its exact Pack revision,
with matching Pack metadata and the complete active Card set. Hidden/deleted
Cards cannot leak into that target. Direct trusted-operator revisions may advance
an otherwise unchanged published snapshot; all revisions remain strictly
increasing, including forward rollback. A candidate at or below a retained Pack
tombstone is rejected. Failed generation/validation/history/catalog writes leave
no partial metadata activation.

Before any revision becomes public, runtime checks enforce strict canonical
PublicManifest fields, >=2 eligible Cards, valid difficulty/relationships,
unique ordered IDs and image keys, complete per-Card/Pack rights attribution,
cleared-test provenance, required images, byte sizes, hashes, image format
headers, trusted signature and archive hash. The offline preparer additionally
validates the complete archive and decodes images. Invalid drafts may remain
saved, but cannot become distributed revisions. Production rights provenance
still requires an explicitly versioned format decision; this ticket does not
relax the cleared-fixture gate.

A Card hide/deletion temporarily suppresses its old public Pack projection.
`publication_suppression` remembers whether that Pack was visible. A matching
validated routine publication may resume that visibility only while the Pack
remains administratively active. An explicit Pack hide/delete/restore/purge
clears prior resume intent, and remains hidden. Thus routine maintenance needs
validation without an extra Owner approval bottleneck, while initial approval
and explicit publishing/unpublishing remain the T35 workflow. No HTTP signing
or publishing endpoint is introduced.

Target delta reads currently reverify complete target artifacts internally,
including unchanged stored images; only the changed descriptors/objects cross
the client transport. This preserves T22's conservative integrity checks and
its O(Pack bytes) Worker/R2 cost. Measuring and optimizing large-Pack validation
and streaming remains separate from this fixture-backed correctness work.

## Verification

`npm run typecheck` and `npm test` exercise the real bundled Worker with local
D1/R2, pinned signing keys and authenticated Firebase fixtures. Tests cover
unchanged/add/edit/image/hide changes, delta reconstruction and skipped bytes,
strict protocol errors, missing history, cache validation, draft publication
validation, races, durable deletion after catalog removal/purge/restore, Topic
cascades and explicit visibility intent.
