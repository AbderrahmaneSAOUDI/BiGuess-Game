# T08 — Native local content storage

`SqliteContentRepository` implements the synchronous T07 `ContentRepository`
contract using `sqlite3`. `openDefault()` selects the application support
directory; `open(path)` supports explicit native database files. The owner closes
the repository. This ticket does not bind it to the UI: bundled content remains
the default, and selection/countdown/reveal do not access this database.

The sqlite3 package bundles native SQLite through Dart build hooks. This requires
Dart 3.10 or newer and a new native application build; `has_native_changes` is set
accordingly. No APK, OTA, backend, or content publication is part of this ticket.
This implementation uses native FFI, not the package's separate web/WASM adapter.

## Schema and migration contract

`ContentDatabase` enables foreign keys on every connection. It acquires an
exclusive transaction before reading `user_version`, applies successive numbered
migrations, checks foreign keys, and commits the new version with the schema.
Failure rolls back DDL/data/version together and closes the connection. Newer
versions are rejected without destructive downgrade. Keep migrations append-only
after shipping. Back up the database before introducing future data conversions;
never recover a failed upgrade by deleting the database.

| Version | Tables and changes |
| --- | --- |
| 1 | Topics, Packs, Cards, installed Packs; required parent foreign keys, unique IDs, nonempty names/image references, boolean/difficulty checks, positive integer revisions and nonnegative integer timestamps |
| 2 | Persistent typed deletion markers, pending-marker index, parent/difficulty/name indexes, monotonic Topic/Pack/installed revision triggers and installed-revision upper bound |
| 3 | Separate installed Card snapshots, backfilled from matching installed/catalog revisions, with a Pack/difficulty query index |

Pack and Topic revisions are container metadata. Cards retain exactly their
canonical gameplay fields; Card edits travel with the containing Pack revision.
Installed revision and UTC installation timestamp are separate from catalog
metadata, so a cached catalog can describe a newer revision than the installation.
Installed Cards are retained independently of cached Card rows. Activating a new
installation requires its revision to match the cached Pack; its Card snapshot
and installed revision commit in the same transaction. Retrying an existing
installed revision leaves its snapshot unchanged. The caller must verify and
install the corresponding files before recording installation here.

Earlier schemas cannot reconstruct overwritten installed Cards when cached and
installed revisions already differ. Such upgrades fail with an explicit error
and preserve the original database. Restore verified installed content with
matching metadata before retrying; never relabel newer cached Cards as installed
or delete the database as automatic recovery.
Pack/topic deletion is restricted while dependent rows exist. Tombstones have no
target foreign key so evidence survives eventual target removal.

## Repository behavior and boundaries

- `putContent` transactionally upserts cached metadata without replacing parent
  rows, deleting absent records, changing installed Cards, or marking Packs installed.
  Existing IDs retain insertion order; all returned collections are immutable.
  File validation, staging, replacement and activation belong to T10.
- Read-interface methods expose stored content, including draft metadata.
  `getEligibleCards` reads installed Card snapshots to build a non-deleted, one-Topic pool across
  explicitly selected Pack IDs and cumulative difficulty. The required
  `includeUnpublished` argument keeps the open existing-download publication
  policy with the caller; this ticket chooses no default. The caller materializes
  the game snapshot in memory before play; no mutable active game state is stored
  here.
- Local searches use indexed literal name prefixes (wildcards are escaped), with
  SQLite's ASCII-only case folding. Unicode names and image paths are preserved;
  this is not a multilingual full-text or substring search implementation.
- `recordDeletion` persists pending evidence and ignores duplicate/stale revisions.
  It never removes content or files. `acknowledgeDeletion` matches the exact
  revision, preventing an older snapshot from acknowledging newer evidence.
  Actual safe-point purging and synchronization belong to T43.

## Verification

`flutter test test/integration/sqlite_content_repository_test.dart` uses real
temporary database files with HTTP disabled. It covers fresh creation, reopen,
restart, the frozen v1 fixture upgrade, index query plans, SQL constraints,
transaction rollback, failed-upgrade retry, unsupported future versions,
installation and tombstone persistence, and lossless round trips of every
bundled Topic/Pack/Card and image path. It does not simulate a native process
crash, install an Android binary, or validate imported image files.
