# Content API (T20–T22)

Isolated TypeScript Cloudflare Worker, D1 migrations and private R2 objects.
`../biguess-api/` remains the separate legacy game-record API. No Flutter client,
gameplay dependency, cloud resource, deployment or production credential is added.

The public catalog implements the frozen [v1 contract](../../contracts/content/v1/README.md).
Immutable signed publications and anonymous downloads are described in
[PUBLISHING.md](PUBLISHING.md). Studio mutations and sync remain separate tickets.
The initial `storage_fixtures` table remains isolated from catalog data.

## Public read-only catalog

- `GET /content/v1/catalog/topics` returns published, nondeleted Topics.
- `GET /content/v1/catalog/packs?topicId=<id>` returns published, nondeleted
  Packs under that visible Topic. Counts/hash/revision describe the complete
  published revision; draft edits must not replace this projection.

Both accept `limit` (1–100, default 50) and opaque `cursor`. IDs sort by exact
UTF-8 bytes, independent of names. Summaries contain only the frozen Topic/Pack
fields; no Card or session endpoints or online gameplay calls are added.
There is no player authentication. Wildcard CORS allows anonymous clients,
including conditional requests; `OPTIONS` permits GET and `If-None-Match`.
Unknown Topic is 404, unpublished Topic 403, deleted Topic 410. Invalid queries
or methods are 400; unsupported API majors are 426. All use the v1 error envelope
and `no-store`; storage failures are retryable 503 with `Retry-After: 5`.

D1 migration `0002_catalog.sql` adds the published summary projection and durable
pagination snapshots. No public mutation route or production content seed exists.
Tests populate synthetic summaries directly; an empty migrated DB returns an
empty catalog. The trusted publisher atomically projects validated complete
published revisions with their active Card count and exact manifest hash.

Snapshots bind endpoint, Topic, limit, order and the complete summary set for
10–20 minutes. Opaque cursors authenticate their position with a server-only
random snapshot secret. New content and metadata edits do not alter existing
pages. Every read rechecks current visibility of the parent and **all** snapshot
entries before any 304; missing/hidden/deleted entries expire the snapshot (409).
Clients restart pagination and retain their last complete successful catalog.
Snapshot rows are retained so valid expired cursors remain distinguishable from
invalid ones; retention/compaction is an operational follow-up before large-scale
traffic. Snapshots use one D1 row and are subject to D1's row-size limit; oversized
catalogs fail as 503 rather than silently returning incomplete pages.

Successful pages use `public, max-age=60, must-revalidate` and a strong quoted
SHA-256 ETag of exact response bytes. Conditional GET supports ETag lists, weak
validators and `*`, returning an empty 304 with the same cache/CORS headers.
Identical first pages share a snapshot within a ten-minute window; a new window
can change the ETag even when summaries are unchanged. Visibility rechecks apply
to requests reaching the service; already cached bytes remain subject to the
contract's 60-second freshness window.

## Local development

Requires Node 22+ and npm. Run in this directory:

```bash
npm ci
npm run setup
npm run dev
```

No Cloudflare login, API token or existing bucket/database is needed. Open the
loopback URL printed by Wrangler (normally `http://127.0.0.1:8787`):

```bash
curl --fail http://127.0.0.1:8787/health
curl --fail http://127.0.0.1:8787/__fixture --output /tmp/biguess-fixture.webp
sha256sum /tmp/biguess-fixture.webp
```

The latter reads D1 metadata, fetches R2 bytes, checks length/SHA-256 and returns
the fixture as WebP. Its expected hash is in `fixtures/metadata.json`. It exists
only in the local environment; staging returns 404. Health is process liveness,
not a database-readiness assertion. Missing schema/seed/object and corrupt bytes
return 503 without exposing SQL errors. No HTTP write routes exist.

`fixtures/image.webp` is an original 8×8 solid-color lossless WebP (38 bytes),
with no third-party content. Its bytes, key, hash and SQL are fixed in source;
no timestamps, random IDs or credentials are generated. Seeds upload R2 before
upserting D1. Repeating setup leaves one identical row/object. Seed scripts
hardcode `--env local --local`; they reject remote/environment overrides.

Wrangler persists local state under ignored `.wrangler/state/`. Migrations, seeds
and dev use that same default. For an isolated copy, use the same absolute state
directory for all three commands:

```bash
npx wrangler d1 migrations apply DB --env local --local --persist-to /tmp/biguess-content-state
npm run seed -- --persist-to /tmp/biguess-content-state
npm run dev -- --persist-to /tmp/biguess-content-state
```

## Checks

```bash
npm run typecheck
npm test
npm run build
```

Tests execute in workerd/Miniflare. Catalog tests validate actual HTTP payloads
with the shared Python contract validator (install `contracts/content/requirements.txt`).
They cover visibility, byte ordering, stable snapshots, cursor tampering/expiry,
ETags, anonymous CORS, structured errors and storage failure. Storage tests cover D1/R2 reads, corruption and
missing-storage responses, schema constraints, staging fixture exclusion, seed
guardrails, configuration isolation and secret ignore rules. The persistence
test applies real Wrangler migrations twice and seeds twice in a temporary
directory, then serves those bytes through the Worker and checks the row count.
`npm run build` is a staging **dry run**, with no deployment. The lockfile pins
the toolchain; a fresh `npm ci` reproduces it.

## Environments and secrets

`wrangler.json` declares `local` and `staging` independently, including all
non-inherited D1/R2 bindings. Database UUIDs are deliberately fake placeholders;
staging names must also be replaced with resources owned by the operator. There
is no production environment, account ID, public route or automatic deployment.
`remote: false` keeps dev bindings local; remote CLI commands still require care.
`src/env.ts` defines the binding types checked by TypeScript.

No secrets are currently required. Future local secrets belong in ignored
`.dev.vars.local` (see `.dev.vars.example`); deployed secrets use Wrangler's
secret store for the explicitly selected environment. Use least-privilege tokens
from a CI secret store, never Wrangler vars, committed files, Flutter source,
assets, `--dart-define`, or bundled configuration. `.env*`, `.dev.vars*`, local
state and dependencies are ignored. R2 remains private; there is no public
bucket URL or general object-proxy route.

## Manual deployment plan (not executed by setup/tests)

1. Run all checks above. Establish T19 contracts before building content routes.
2. In an approved nonproduction Cloudflare account, manually create a dedicated
   staging D1 database and private R2 bucket. Record resource/account ownership;
   substitute the staging UUID and bucket name in `wrangler.json`. Never reuse
   the legacy record database or production resources. Keep local bindings intact.
3. Review `npx wrangler deploy --env staging --dry-run`. Use authenticated
   operator access to test the Worker while `workers_dev` is false; any public
   staging route requires a separate reviewed configuration change.
4. Before remote migrations, export the selected staging DB with
   `npx wrangler d1 export DB --env staging --remote --output <backup.sql>`.
   Store backups securely outside source control, verify their resource ID and
   timestamp, and rehearse restore into a disposable database. An initial empty
   database needs no data backup.
5. Only with deployment authorization, run
   `npx wrangler d1 migrations apply DB --env staging --remote`, then
   `npx wrangler deploy --env staging`. Do not run the local fixture seed against
   staging. Verify `/health` and that `/__fixture` is 404. Record deployment ID,
   prior Worker version, migration ledger, backup reference and Git commit.
6. Production provisioning, routing, credentials and deployment remain a separate
   approved operation; this scaffold has no production target or CI deploy job.

## Rollback and migration policy

Keep numbered migrations immutable once applied. Wrangler records applied files
in `d1_migrations`; repeat `migrations apply` is a no-op. Replaying the raw first
SQL file is not the migration mechanism. Prefer additive, backward-compatible
schema changes, deploying readers compatible with old/new schemas before writes.
Test new migrations against both empty and representative existing local data.

For a code regression, use `npx wrangler rollback <previous-version-id> --env staging`
after checking that the previous Worker supports the current schema. Worker
rollback does **not** undo D1 migrations or R2 changes. There is no automatic
down migration. For a data/schema regression, stop writers, preserve a backup of
the failed state, restore the pre-change export into a **new disposable/staging
database**, validate row counts and integrity/foreign keys, and rebind a compatible
Worker after review. Rehearse before applying the same procedure to production;
restoring an old snapshot can lose newer writes. Prefer a tested forward repair
migration when preserving those writes is required.

Retain previous R2 objects throughout the rollback window; code/D1 restores do
not restore deleted objects. The T22 publisher retains immutable revisions
and verifies object hashes before metadata becomes visible. Never purge a
bucket as part of deployment rollback. For local reset, stop dev and select a
fresh state directory, then rerun migrations/seeds; no remote deletion is needed.

References: [D1 migrations](https://developers.cloudflare.com/d1/reference/migrations/),
[local D1](https://developers.cloudflare.com/d1/best-practices/local-development/),
[environment bindings](https://developers.cloudflare.com/workers/wrangler/configuration/),
[R2 Worker bindings](https://developers.cloudflare.com/r2/api/workers/workers-api-usage/).

### Studio authentication (T23)

All `/studio` and frozen `/content/v1/studio` requests authenticate before public routing.
`/content/v1/studio/...` uses the same boundary as `/studio/v1/...`. Send a Firebase **ID token**
from Google sign-in as `Authorization: Bearer <token>`; Google OAuth access tokens,
Google ID tokens and Firebase custom tokens are not accepted. Verification uses
RS256, Google's fixed Secure Token public JWKS endpoint, the configured Firebase
project issuer/audience, expiry/issued/authentication times, verified email and
`firebase.sign_in_provider = google.com`. See [Firebase token verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens).
No service-account private key or Firebase Admin credential is needed by this Worker.

Configure these **server-side** bindings for each environment:

- `FIREBASE_PROJECT_ID`: the trusted Firebase project ID, never taken from a token.
- `STUDIO_USERS`: a Worker secret containing JSON entries with `uid`, `email`, and
  `role` (`owner_admin` or `collector`). Both Firebase UID and verified email must
  match exactly one entry (email comparison is case-insensitive).

For local development use ignored `.dev.vars.local`; for staging use
`npx wrangler secret put STUDIO_USERS --env staging` and configure the project ID
in the environment. Never put real allowlists, credentials or bearer tokens in
source control, Flutter defines, frontend bundles or logs. An empty allowlist
admits nobody. Missing/invalid configuration or key-service failure fails closed.
Removing an allowlist entry revokes Studio access on subsequent requests; roles
are read from this server data every time. Token claims, headers, query parameters
and request bodies cannot grant roles. Moderator/community roles are unsupported.
Firebase account revocation/disablement is not queried on each request; signed ID
tokens remain usable until expiry unless the operator removes the allowlist entry.

`GET /studio/v1/session` returns only the authenticated `{ uid, email, role }` with
`Cache-Control: no-store`. Invalid/missing tokens return 401 with a Bearer challenge;
non-allowlisted users and denied operations return 403. Public `/content` endpoints
remain anonymous; Mobile gameplay requires no player account.

| Operation | Owner Admin | Collector |
| --- | --- | --- |
| Read Topics/Packs/Cards and own session | Yes | Yes |
| Create/edit/hide Packs and Cards | Yes | Yes |
| Manage Topics, initial publishing, Studio users/roles | Yes | No |
| Delete (soft or permanent) or restore any resource | Yes | No |

The explicit route map in `src/studio-auth.ts` protects `/studio/v1/{topics,packs,cards,users}`:
collection POST is create, item PATCH is edit, item DELETE is soft-delete, and item
POST suffixes are `hide`, `publish`, `soft-delete`, `permanent-delete`, `restore`.
Unknown methods/routes fail closed. Content creation/editing, hiding and Owner
administrative lifecycle operations now share the versioned atomic
[Studio mutation implementation](STUDIO.md). `POST /studio/v1/batches` and
`/content/v1/studio/batches` validate and authorize every operation before writing.
Item mutation routes accept a single matching operation in the same StudioBatch
envelope. Studio content reads, user management and publishing still return 501;
these are separate roadmap work. Hide permission never implies deletion.

`npm test` exercises the real bundled Worker with locally signed RSA tokens and
intercepted Google JWKS discovery. There is no production test-key/auth-bypass
binding, and the tests require neither real credentials nor network access to Google.
