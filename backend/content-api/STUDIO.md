# Administrative mutations (T24)

The Worker implements the frozen [v1 Studio contract](../../contracts/content/v1/README.md#studio-mutations-concurrency-and-authorization).
Apply `0004_studio.sql` through the existing **local** migration workflow; this
change does not deploy or apply a remote migration.

Send `POST /studio/v1/batches` (alias `/content/v1/studio/batches`) after an explicit
Studio Save/import action, with a Firebase Google ID token, `Idempotency-Key`, and
exactly one revision precondition:

- New Topic/Pack: `If-None-Match: *`, including its create operation.
- Existing Topic/Pack, including Card-only changes: `If-Match: "rev-N"`.

```json
{
  "protocolVersion": 1,
  "aggregate": { "resourceType": "pack", "id": "shapes" },
  "operations": [
    { "resourceType": "pack", "id": "shapes", "action": "create",
      "value": { "name": "Shapes", "topicId": "learning" } }
  ]
}
```

The Topic must already exist. A batch contains 1–100 final operations, unique by
resource type and ID. The body is limited to 256 KiB. A Topic batch touches that
Topic; a Pack batch touches that Pack and its Cards. Pack create and Cards may
appear in either order. Parent deletion/restore/purge must be a separate commit
from explicit child operations. Empty draft Packs are allowed.

`create`/`update` supply all mutable fields: Topic `{name}`, Pack `{name, topicId}`,
Card `{name, packId, imageReference, difficulty}`. Names are trimmed/nonempty,
difficulty is integer 1–3, and extra fields (including actor, role, deletion,
revision or publication state) are rejected. Pack Topic reassignment and
cross-Pack Card moves are rejected; a multi-aggregate move protocol is deferred.
Images reference operator-managed R2 `objects/<sha256>.<webp|png|jpg>` objects;
the Worker checks existence, byte hash, media type and image format header.
No arbitrary URLs, uploads or client-supplied image authority are accepted.

Collectors can create/update/hide Packs and Cards and `activate` hidden Cards.
Topic management and all `softDelete`, `restore`, and `permanentDelete` operations
require Owner Admin. Every operation is authorized before any write, including
operations later in a mixed batch. `publish` is Owner-only but remains 501 until
the separate validated publishing workflow; this API cannot publish draft bytes.

Existing collection POST, item PATCH, item DELETE and item POST action routes
(`hide`, `soft-delete`, `restore`, `permanent-delete`) also accept a **StudioBatch
body containing exactly one matching operation**. They use the same preconditions,
idempotency, validation and transaction path. Card routes still specify their Pack
aggregate. Prefer batches for imports and multi-row saves. Studio content read,
image upload and user-management operations remain outside T24.

Success is a `StudioResult` with authenticated UID `actorId`, server timestamp,
aggregate revision and `ETag: "rev-N"`; all responses are `no-store`. Each commit
advances the Topic or Pack once, including Card-only batches. Missing preconditions
return 428; malformed requests/preconditions return 400; invalid fields,
relationships or state transitions return 422. Stale revisions return 412
`revision_conflict` with `currentRevision`. Reconcile before another explicit save.

Idempotency is scoped to authenticated UID. Canonical body plus preconditions and
the original result are saved atomically. Identical retries return the original
result before checking the now-stale revision; changed requests using the same key
return 409 `idempotency_conflict`. Records are retained indefinitely (at least the
contract's 30-day minimum). Authorization is checked again on retries.

`studio_entities` holds administrative records separately from public immutable
artifacts. The migration fences pre-existing catalog Topic/Pack identities and
revisions; importing their Card authoring data from frozen R2 manifests is not an
SQL migration. Newly created Cards are maintained here. No draft edit rewrites
old manifests, receipts or archives. Pack revision/delta distribution is T25;
validated publication is T35.

Soft deletion retains the record and cascades Topic → Packs → Cards. Descendant
Packs receive their own next revision. Every affected entity gets a concise audit
entry (batch, UID, role, resource, action, revision, timestamp) and an append-only
tombstone. Hiding creates no tombstones. Visibility/deletion changes immediately
suppress existing public discovery/new downloads; Card hiding/deletion suppresses
the old Pack projection until a validated replacement can be published. Installed
offline gameplay is independent. Public tombstone/delta transport belongs to T25.

Restore requires a nondeleted parent and restores only the selected entity into
hidden state; descendants require explicit restoration. It never republishes
content or removes deletion evidence. Permanent deletion requires prior soft
deletion and purged children. It erases mutable product fields while retaining
identity/revision fences, idempotency results, audit attribution and tombstones.
Historical immutable R2 publications are retained; physical shared-object garbage
collection is a separate retention operation, never a Collector mutation.

Validation reads the aggregate, descendants and parent Topics with a shared D1
mutation generation in one transaction. The write transaction first checks that
generation, then commits records, audit, tombstones, public suppression and
idempotency together. A concurrent administrative change, even to a different
aggregate, may conservatively cause a 412. No partially validated commit or silent
merge is possible. Operator-only publication/import must be coordinated with
administrative writes; publication integration is a later ticket.

`npm run typecheck` and `npm test` verify the bundled Worker with real signed
Firebase fixtures, D1 transactions and R2 bytes. No production token or cloud
service is required.
