# Content infrastructure (T20)

Isolated TypeScript Cloudflare Worker, D1 migrations and private R2 objects.
`../biguess-api/` remains the separate legacy game-record API. No Flutter client,
gameplay dependency, cloud resource, deployment or production credential is added.

This is infrastructure, not the T21 catalog or T22 publishing implementation.
The initial `storage_fixtures` table stores structured object metadata only; it
does not define Topic/Pack/Card, revision or tombstone schemas. Future content
migrations must follow the T19 shared contracts and approved decisions.

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

Tests execute in workerd/Miniflare. They exercise D1/R2 reads, corruption and
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
not restore deleted objects. Future publishing must retain immutable revisions
and verify object hashes before metadata becomes visible (T22). Never purge a
bucket as part of deployment rollback. For local reset, stop dev and select a
fresh state directory, then rerun migrations/seeds; no remote deletion is needed.

References: [D1 migrations](https://developers.cloudflare.com/d1/reference/migrations/),
[local D1](https://developers.cloudflare.com/d1/best-practices/local-development/),
[environment bindings](https://developers.cloudflare.com/workers/wrangler/configuration/),
[R2 Worker bindings](https://developers.cloudflare.com/r2/api/workers/workers-api-usage/).
