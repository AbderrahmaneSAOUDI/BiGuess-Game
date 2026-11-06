-- Published summary projection. Writers/publishing are separate tickets: draft
-- edits must never replace these summary fields until a complete revision is ready.
CREATE TABLE catalog_topics (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL CHECK(length(trim(name)) > 0 AND name = trim(name)),
  revision INTEGER NOT NULL CHECK(revision BETWEEN 1 AND 9007199254740991),
  published INTEGER NOT NULL DEFAULT 0 CHECK(published IN (0, 1)),
  deleted INTEGER NOT NULL DEFAULT 0 CHECK(deleted IN (0, 1))
);
CREATE TABLE catalog_packs (
  id TEXT PRIMARY KEY NOT NULL,
  topic_id TEXT NOT NULL REFERENCES catalog_topics(id),
  name TEXT NOT NULL CHECK(length(trim(name)) > 0 AND name = trim(name)),
  revision INTEGER NOT NULL CHECK(revision BETWEEN 1 AND 9007199254740991),
  card_count INTEGER NOT NULL CHECK(card_count BETWEEN 2 AND 9007199254740991),
  manifest_sha256 TEXT NOT NULL CHECK(length(manifest_sha256) = 64 AND manifest_sha256 NOT GLOB '*[^0-9a-f]*'),
  published INTEGER NOT NULL DEFAULT 0 CHECK(published IN (0, 1)),
  deleted INTEGER NOT NULL DEFAULT 0 CHECK(deleted IN (0, 1))
);
CREATE INDEX catalog_packs_topic ON catalog_packs(topic_id, published, deleted, id);
-- Server-only pagination state; never included in public summaries.
CREATE TABLE catalog_snapshots (
  id TEXT PRIMARY KEY NOT NULL,
  scope TEXT NOT NULL,
  page_limit INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  secret TEXT NOT NULL,
  items TEXT NOT NULL
);
