# Content protocol v1 (T19, frozen)

This directory is the shared wire contract for Mobile, Studio and the future
content service. It deploys nothing and changes no app behavior. `openapi.json`
defines HTTP operations; `schemas.json` contains independently usable JSON Schema
2020-12 definitions. The schemas, this document's semantic rules and fixtures are
normative together. No Flutter, Riverpod, SQL or cloud SDK types cross this boundary.
The existing game-record Worker is a separate service.

## Compatibility and identity

The API base is `/content/v1`; all API envelopes require `protocolVersion: 1`.
The manifest preserves the existing T09 `schemaVersion: 1` full-Pack format,
without adding an API envelope inside the archive. Protocol, manifest schema,
entity revisions and app versions are independent version domains.

Objects are closed (`additionalProperties: false`), unknown enums/versions fail
closed, and fields are required unless the schema explicitly says otherwise.
In v1 even adding a field or enum is incompatible: introduce `/content/v2` and
new fixtures instead. Documentation/fixture corrections that do not change valid
payloads are patch changes to OpenAPI `info.version`. Clients must never coerce
unknown versions into v1, delete installed content on decode errors, or overwrite
a working installation when a response is unsupported. Unknown API majors return
426 `unsupported_protocol` using the v1 error envelope when possible; clients
cannot assume an unknown major's error format. Server rollout must retain v1
until a separately approved retirement plan exists; no forced online validation.

UTF-8 JSON only; reject duplicate object keys, NaN/infinities, unpaired surrogates,
boolean numbers and fractional numeric values. Producers emit integer tokens.
Numbers are at most JavaScript's exact integer maximum (9007199254740991).
IDs are opaque, case-sensitive, immutable Unicode strings with no whitespace or
control characters; preserve spelling and normalization. IDs must not be derived
from display names, positions or URLs. Resource type plus ID identifies a record;
Card identity is scoped to its Pack, and a Card cannot move between Packs. Pack
Topic associations are immutable after creation. Renames preserve identity;
deleted identities are never reassigned. Names are trimmed nonempty text;
duplicate names are allowed. Canonical Card fields remain `id`, `packId`, `name`,
`imageReference`, `difficulty` (integer 1–3). Operational state stays separate.

## Public discovery and pagination

`GET /catalog/topics` lists only published, nondeleted Topics.
`GET /catalog/packs?topicId=...` lists only published, nondeleted playable Packs
under that visible Topic. Counts refer to active Cards in the published revision;
no Card-list/gameplay API exists. Unknown Topic returns 404; hidden Topic 403
`unavailable`; deleted Topic 410 `deleted`. These errors do not authorize a Pack
purge; only a Pack tombstone does.

Both endpoints accept `limit` 1–100 (default 50) and opaque `cursor`. Items are
ordered by exact UTF-8 ID bytes. The first page binds a catalog snapshot, filters,
limit and order to subsequent cursors. Pass only `nextCursor` unchanged with the
same query; null ends the list. Snapshot contents and IDs cannot drift or repeat
between pages. An invalid/tampered cursor is 400; an expired snapshot is 409
`cursor_expired`, requiring a new first page and discarding the partial result.
Missing catalog rows never mean deletion. Each request rechecks current visibility
and deletion, even for snapshot pages; if entries have become unavailable, expire
the snapshot rather than leaking stale entries. Clients cache the last complete
successful catalog, never merge partial pages into it as a complete replacement.

## Caching, revisions and integrity

GET responses include a strong quoted ETag equal to SHA-256 of the exact UTF-8
response bytes (`"<64 lowercase hex>"`). Use `If-None-Match` on the identical URL,
query and representation; equality yields 304 with no body and the ETag/cache
headers. Check authorization/availability before responding 304. Catalog and
latest-download descriptors use `public, max-age=60, must-revalidate`; deltas use
the same policy. Immutable revision manifests use `public, max-age=31536000,
immutable`. Studio/revision POST responses use `Cache-Control: no-store`.
Public artifact bytes already downloaded/cached cannot be remotely recalled.

Topic and Pack revisions are positive, monotonically increasing integers, never
reused even on rollback/restore. Every committed Pack metadata/Card/image/visibility
change increments the Pack revision exactly once per atomic Studio batch. Card
changes use that containing Pack revision, not independent Card revision fields.
Topic edits increment Topic revision. A Topic deletion also creates newer Pack
tombstones for every descendant; Topic hiding creates none. Publish only a fully
validated complete revision; draft revisions may have gaps from the public
sequence. A rollback publishes previous content under a new revision. The same
Pack/revision must never resolve to different manifest bytes or hashes.

Image keys are `objects/<sha256>.<webp|png|jpg>`, hashes cover raw image bytes,
and size/media type/decoded image format must agree. The manifest SHA-256 covers
the exact canonical T09 bytes (UTF-8, sorted keys, compact separators, final LF);
the archive hash covers all ZIP bytes. These are external digests, never circular
self-hashes. HTTPS URLs are transport locators and may change without changing
content identity; never use URL text as an image hash. Verify both sizes and
hashes before activating downloaded content. Checksums are integrity checks;
publisher signature/key distribution is deferred to T22, not implied here.

## Initial download and delta

`GET /packs/{packId}/download` resolves the latest published revision to a
`Download` descriptor with manifest and complete `.biguesspack` URLs, hashes and
archive byte length. `GET /packs/{packId}/revisions/{revision}/manifest` returns
the exact full manifest. The descriptor and artifact references must describe
one immutable revision. A superseding publication during download must not mix
its bytes into the original download. Referenced HTTPS objects must stay fetchable
for that immutable artifact's retention period; interrupted retries use the same
revision. A missing revision is 404; hidden/unpublished Pack is 403 `unavailable`;
a deleted Pack is 410 `deleted` and is resolved through `/sync/revisions`.

The local `Manifest` schema preserves both existing provenance modes; the API
uses `PublicManifest`, which rejects `legacy-development`; tests use the cleared Shapes fixture. New
production provenance modes need an explicitly versioned format decision rather
than silently relaxing T09's rights gate. See
[the existing archive contract](../../../docs/migration/PACK_FORMAT.md).

`GET /packs/{packId}/delta?fromRevision=A&toRevision=B` requires A < B and returns
a complete change set between those exact immutable revisions. Apply only to a
verified installed A from that Pack. `upsertCards` contains full records for added
or modified Cards; `removeCardIds` includes Cards absent/hidden/deleted in B, with
no ID in both lists. `objects` lists only new/replaced image objects needed by
upserts and absent from A; unchanged image bytes are never transported. Resolve
object keys relative to the target manifest URL's directory; publishers must
serve that layout. Skip downloading any already verified content-addressed object.
A metadata-only update may have empty arrays. A == B is 400; unchanged detection
uses the revision check endpoint instead.

Fetch and verify the target full manifest by `targetManifestSha256`, merge changes
and retained objects into staging, and require the final Card set, metadata,
relationships, provenance and exact required objects to match that manifest.
The full target manifest is metadata, not permission to redownload unchanged
images. Reject incomplete, duplicate, cross-Pack, conflicting or hash-invalid
changes. Commit one complete generation atomically, keeping the old installation
and active game resources until a safe point. Delta expiry/missing history is 409
`delta_unavailable`; resolve a new full descriptor, never apply a partial delta.
These are transport/install requirements for future clients, not a new client.

## Revision checks and tombstones

`POST /sync/revisions` submits 1–100 distinct installed Pack IDs and known
revisions. Respond exactly once per ID (including IDs no longer in catalog):

| Status | Meaning |
| --- | --- |
| `unchanged` | Same published revision and manifest hash. |
| `updateAvailable` | Higher published revision and new manifest hash. |
| `unavailable` | Hidden/unpublished Pack or ancestor; no tombstone. |
| `deleted` | Authorized deletion evidence with matching Pack ID, newer revision, UTC deletion time and administrative reason. |
| `unknown` | ID never known; no authority to purge a local installation. |

Known revision ahead of server state is 409 `revision_conflict`; never downgrade.
A deleted Pack is reported as deleted only when its tombstone is newer than the
submitted installed revision; impossible newer client revisions are conflicts.
Tombstones are durable compact per-ID deletion evidence, retained even after
permanent deletion of content/images. Checking explicit installed IDs requires
no global cursor and cannot lose deletion evidence to a catalog page/history
expiry. Retain the last deletion evidence after restore: clients older than that
deletion still receive it; a fresh download resolves a later Owner-published
revision. Restoration does not resurrect an old revision or implicitly publish.

Hide/unpublish does not generate a tombstone. Policy for previously downloaded
hidden Packs remains open in DECISIONS §8.3; `unavailable` must not be interpreted
as deletion or used to invent that policy. Topic cascades issue explicit Pack
tombstones. Stage valid tombstones; apply deletion only on Home/outside gameplay.
Malformed/unknown/conflicting responses leave the installation intact. There are
no realtime listeners, periodic online play validation or gameplay network calls.

## Studio mutations, concurrency and authorization

`POST /studio/batches` accepts one Topic or Pack aggregate and 1–100 operations.
A Topic batch touches that Topic only. A Pack batch touches that Pack and/or its
Cards; relationships must be validated against existing server records as well as
the payload. IDs must be unique per resource within the batch; use one final
operation per resource, not keystroke streams. `update` replaces all mutable
product fields, never identity, publication/deletion state, revision or audit.
Create starts draft/active; publishing is a separate Owner operation. Empty or
insufficient draft Packs may be stored, but automated publication validation
requires at least two active Cards and complete verified images/rights.

For an existing aggregate send `If-Match: "rev-N"` (aggregate revision, not the
GET response-byte ETag). For creating the aggregate send `If-None-Match: *` and
include its create operation. Exactly one precondition is required. Missing is
428 `precondition_required`; both/malformed is 400; stale/existing-create is 412
`revision_conflict` with `currentRevision`. Card-only batches still match their
Pack's aggregate revision. A conflict never silently merges or commits a subset.

`Idempotency-Key` is mandatory. Persist `(actorId, key, canonical request body,
preconditions, result)` atomically with the commit. Identical retries return the
original result/ETag before testing the now-stale precondition; different body or
precondition under the same key is 409 `idempotency_conflict`. Keys are scoped to
the actor and retained at least 30 days; automatic queue retries after 30 days
must reconcile the aggregate and use a new explicit commit/key. A response loss
must never duplicate creation/deletion. Success returns server-derived `actorId`,
`committedAt`, aggregate revision and `ETag: "rev-N"`; actor/role/audit fields are
not accepted in input. All operations, revisions, audit and tombstones commit
atomically. Permanent deletion leaves audit, identity fences and tombstones.

Bearer identity is verified Google authentication plus server-managed allowlist,
role and authorized scope. The future server must enforce this matrix; the
contract validator does not implement authentication or database permissions.

| Operation | Owner Admin | Data Collector within granted scope |
| --- | --- | --- |
| Topic create/update/hide/publish | Yes | No |
| Pack/Card create/update | Yes | Yes |
| Pack hide, Card hide/activate | Yes | Yes |
| Initial Pack publishing | Yes | No |
| Routine edits to published Packs | Yes, automated validation | Yes, automated validation |
| Soft-delete, restore, permanent-delete, any resource | Yes | No |

Deleted resources cannot be edited/published without Owner restore; permanent
purge requires prior soft deletion. Pack create requires an existing nondeleted
Topic. All image references must resolve to verified authorized uploaded objects;
no arbitrary URL/upload is accepted by a Card mutation. Image upload and Studio
read/sync endpoints belong to later tickets. Moderator is absent in MVP.

## Errors

All non-304 JSON errors use `Error`: stable enum `code`, user-safe `message`,
opaque diagnostic `requestId`, `retryable`, nullable `currentRevision`. Clients
branch on code, never parse message. Stack traces, SQL and tokens are excluded.

| HTTP | Codes |
| --- | --- |
| 400 | `invalid_request` |
| 401 | `unauthenticated` |
| 403 | `forbidden`, `unavailable` |
| 404 | `not_found` |
| 409 | `cursor_expired`, `delta_unavailable`, `idempotency_conflict`, `revision_conflict` (future known revision) |
| 410 | `deleted` |
| 412 | `revision_conflict` (Studio precondition) |
| 422 | `validation_failed` |
| 426 | `unsupported_protocol` |
| 428 | `precondition_required` |
| 429 | `rate_limited` (Retry-After integer seconds) |
| 500/503 | `internal_error` |

Only transient rate-limit/service errors are retryable. 409/412 require refresh
or explicit reconciliation, not blind mutation retry. 429/503 use `Retry-After`;
all errors are `Cache-Control: no-store`.

## Verification and reuse

```bash
python3 -m pip install -r contracts/content/requirements.txt
python3 -m unittest discover -s .agents/tests -p test_content_contract.py -v
python3 scripts/validate_content_contract.py TopicPage /path/to/payload.json
```

Import any `$defs` entry from `schemas.json` using a Draft 2020-12 validator with
format checking. `fixtures/*.json` wrap positive examples as `{type, payload}`;
the wrapper is test data, not a wire envelope. `invalid.json` provides portable
negative vectors: load `fixture`, replace/add its JSON Pointer `pointer` with
`value`, then require rejection. These vectors can run in Mobile or Studio tools
without importing Python or Flutter. The Python reference validator additionally
checks cross-record invariants (uniqueness, relationships, delta conflicts,
revision monotonicity); port those checks, not only JSON Schema. Stateful HTTP
preconditions/roles/cache behavior must be tested by T21–T25 implementations.

The manifest and descriptor fixtures are generated from the existing cleared
Shapes export; tests recompute actual artifact digests and reject tampered bytes.
No production signing, live server, deployment or network client is supplied.
The definitions follow [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.1.html) and
[JSON Schema 2020-12](https://json-schema.org/draft/2020-12/json-schema-validation).
