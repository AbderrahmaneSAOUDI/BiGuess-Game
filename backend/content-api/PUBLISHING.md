# Immutable Pack publications (T22)

T22 builds on the T21 catalog migration (`0002_catalog.sql`). Apply additive
`0003_publications.sql` after it. No cloud migration or deployment is performed
by preparation or tests. There is no public publishing HTTP route. Studio
publishing/rights approval and mobile download installation remain later tickets.

## Prepare and trust an artifact

Only the cleared Shapes fixture provenance accepted by the frozen PublicManifest
contract is publishable. Legacy development exports are rejected. Production
provenance needs the versioned format decision described in the v1 contract.

From the repository root, export the complete Pack, using a new revision:

```bash
python3 scripts/export_pack.py fixture test/fixtures/cleared_shapes/pack.json \
  --revision 1 --output /tmp/shapes-1.biguesspack
```

From `backend/content-api`, prepare the bundle with an operator-owned Ed25519
PKCS#8 PEM private key stored outside the repository:

```bash
node scripts/prepare.mjs /tmp/shapes-1.biguesspack /secure/publisher.pem /tmp/shapes-1-publication.json
```

The preparer validates the frozen schema, strict canonical manifest bytes,
archive entries, rights provenance, decoded image formats, sizes and SHA-256
hashes before signing. It refuses to overwrite output. The same archive and key
produce identical artifacts and receipt. No timestamp or random field is signed.
No private key is returned or sent to the Worker. Tests generate ephemeral keys.

Provision `PUBLICATION_KEYS` on the Worker as JSON mapping key ID to base64 DER
SPKI public key. Key ID is the lowercase SHA-256 of the DER SPKI bytes. The
`trustedKeys` field in a prepared bundle is a provisioning aid, **not** an
in-band trust source: `publish()` ignores it. The operator must authenticate and
pin the public key separately. Clients must similarly pin approved keys through
a trusted application/configuration release, never trust a key supplied with an
unverified download. Retain old verification keys while their revisions remain
readable; rotation adds a trusted key before using it, and removes an old key
only under an explicit revocation/retention decision.

The detached receipt v1 contains `schemaVersion: 1`, `algorithm: "Ed25519"`,
`keyId`, `statement` and base64 `signature`. Signed bytes are UTF-8 JSON of these
statement fields **in this order**, compact separators, with a final LF:

```text
archiveSha256, archiveSizeBytes, domain, manifestSha256,
manifestSizeBytes, packId, revision, topicId
```

`domain` is exactly `biguess-pack-publication-v1`. Hashes cover the exact canonical
manifest and all ZIP bytes; sizes are positive exact integers. Verify the Ed25519
signature with the pinned key, domain, IDs, revision, hashes and sizes before
accepting bytes. Receipt transport is separate so frozen v1 manifest/Download
payloads gain no incompatible fields. This backend implements verification;
mobile signature verification/installation is not added by T22.

## Publish and retain

`src/publication.ts::publish(env, bundle, expectedRevision)` is a trusted internal
operator primitive. It is not exported through a Worker request or RPC handler.
The caller must supply the current committed revision (0 for a new Pack).
The publication function verifies the trusted signature and artifacts, then:

1. Conditionally creates `manifests/<sha256>.json`, `objects/<sha256>.<ext>` and
   `archives/<sha256>.biguesspack` using R2's create-only ETag precondition and
   upload checksum. Existing keys are read and verified, never overwritten.
2. Reads back and checks every referenced image, manifest and archive.
3. Runs one D1 batch inserting immutable history, moving current/previous heads
   and projecting Topic/Pack catalog metadata. SQL triggers enforce compare and
   swap, increasing revisions, immutable Pack/Topic relationships and history.

A write failure before the D1 batch leaves only undiscoverable orphan objects.
A SQL failure rolls back the entire metadata batch. A competing publisher with
a stale expected revision cannot replace the winning revision. An identical
retry after an ambiguous successful commit receives a conflict; reconcile the
stored head/receipt rather than inventing another publication. Retrying a failed
pre-commit attempt safely reuses matching immutable objects.

Existing catalog visibility/deletion flags are preserved; publishing does not
restore hidden/deleted records. New fixture records start published through this
trusted primitive. This is not Studio's Owner approval workflow (T35).

All history and R2 objects are retained indefinitely by this implementation;
there is no garbage collector, delete or overwrite path. Keep the bucket private,
disable lifecycle deletion for retained artifacts, and restrict write/delete IAM
access to operators. R2 application preconditions do not protect against an
operator bypassing this code. Retain previous objects and verification keys for
rollback. Publish the previous validated content under a **new higher revision**;
never point an old revision at different bytes or decrement the active head.
`previous_revision` identifies the preceding committed generation, and older
history remains accessible too. A damaged existing content-addressed key blocks
publishing rather than being silently repaired; operator recovery is separate.

The storage transaction uses [D1 batch rollback](https://developers.cloudflare.com/d1/worker-api/d1-database/#batch).
Create-only writes use the [R2 conditional API](https://developers.cloudflare.com/r2/api/workers/workers-api-reference/).
D1 and R2 are not one distributed transaction: the visibility guarantee assumes
retained, immutable objects are not removed by external operators after checking.

## Anonymous downloads

- `GET /content/v1/packs/{packId}/download` returns the frozen v1 Download descriptor.
- `GET /content/v1/packs/{packId}/revisions/{revision}/manifest` returns exact manifest bytes.
- `GET /content/v1/packs/{packId}/revisions/{revision}/signature` returns the detached receipt.
- `GET /content/v1/packs/{packId}/revisions/{revision}/archive.biguesspack` serves the complete archive.
- `GET /content/v1/packs/{packId}/revisions/{revision}/objects/{sha256}.{ext}` serves only images referenced by that revision.

Artifact URLs share the manifest's directory, so relative image references work.
The descriptor and manifest include a `Link: <.../signature>; rel="describedby"`
header. No signature query token or expiring R2 presigned URL is used: public
content supports anonymous downloads/retries, with the private bucket behind a
read-only Worker. No listing, arbitrary-key proxy or draft-object route exists.
Public HTTPS origins generate HTTPS descriptors; local development uses loopback
HTTP. These endpoints check Pack/Topic visibility and committed history before
serving any artifact or 304. Hidden content returns 403, deleted content 410,
unknown revisions/objects 404, and missing/altered artifacts or unknown signing
keys return retryable no-store 503. Missing a revision is never deletion evidence.

All successful responses have SHA-256 ETags over exact response bytes, anonymous
CORS, conditional GET and signature Links. Latest descriptors cache for 60 seconds;
immutable artifacts cache for one year. Revoking visibility cannot recall bytes
already cached/downloaded. Prior committed revisions remain readable while the
Pack and Topic are visible, even after a superseding publication.

Currently reads reverify the entire Pack before serving, including before 304,
and buffer artifact bytes. This deliberately conservative fixture implementation
has O(Pack bytes) read cost per request and Worker memory/CPU limits; production
large-Pack streaming/verification and budgets need separate measurement before
rollout. It fails rather than serving a partial or unchecked download.

## Verification

```bash
npm run typecheck
npm test
```

The workerd/D1/R2 publication tests use the cleared fixture only. They verify
repeatable signatures, untrusted keys, tampered/missing bytes, checksum errors,
every interrupted upload stage, no catalog drift during writes, competing
publishers, transaction rollback on catalog failure, retained revisions, forward
rollback, frozen JSON contracts, anonymous access, visibility before cache
revalidation, immutable-key collision refusal, and full downloaded-archive/image
validation. `test/publication-worker.ts` provides a test-only publishing boundary
and fault injection; the deploy entrypoint never imports it.
