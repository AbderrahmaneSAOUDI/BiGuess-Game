-- Administrative drafts are separate from immutable public artifacts/projections.
-- Fences survive purge, so IDs and revision histories can never be reused.
CREATE TABLE studio_entities (
  resource_type TEXT NOT NULL CHECK(resource_type IN ('topic', 'pack', 'card')),
  id TEXT NOT NULL,
  parent_id TEXT,
  value TEXT CHECK(value IS NULL OR json_valid(value)),
  state TEXT NOT NULL CHECK(state IN ('active', 'hidden', 'deleted', 'purged')),
  revision INTEGER NOT NULL CHECK(revision BETWEEN 1 AND 9007199254740991),
  PRIMARY KEY(resource_type, id),
  CHECK((resource_type = 'topic') = (parent_id IS NULL)),
  CHECK((state = 'purged') = (value IS NULL))
);
CREATE INDEX studio_parent ON studio_entities(resource_type, parent_id);
CREATE TABLE studio_generation (id INTEGER PRIMARY KEY CHECK(id = 1), generation INTEGER NOT NULL);
INSERT INTO studio_generation VALUES (1, 0);
CREATE TABLE studio_commits (
  actor_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  fingerprint TEXT NOT NULL,
  request_json TEXT NOT NULL CHECK(json_valid(request_json)),
  result TEXT NOT NULL CHECK(json_valid(result)),
  batch_id TEXT NOT NULL UNIQUE,
  expected_generation INTEGER NOT NULL,
  PRIMARY KEY(actor_id, idempotency_key)
);
-- Validation reads a transactional snapshot. This guard closes every race,
-- including a concurrent parent deletion, before any writes in the D1 batch.
CREATE TRIGGER studio_commit_guard BEFORE INSERT ON studio_commits
BEGIN
  SELECT CASE WHEN NEW.expected_generation != (SELECT generation FROM studio_generation WHERE id = 1)
    THEN RAISE(ABORT, 'studio_conflict') END;
END;
CREATE TRIGGER studio_commit_generation AFTER INSERT ON studio_commits
BEGIN UPDATE studio_generation SET generation = generation + 1 WHERE id = 1; END;
CREATE TABLE studio_audit (
  batch_id TEXT NOT NULL REFERENCES studio_commits(batch_id),
  actor_id TEXT NOT NULL,
  actor_role TEXT NOT NULL CHECK(actor_role IN ('owner_admin', 'collector')),
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  action TEXT NOT NULL,
  revision INTEGER NOT NULL,
  committed_at TEXT NOT NULL,
  PRIMARY KEY(batch_id, resource_type, resource_id)
);
CREATE TABLE studio_tombstones (
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  revision INTEGER NOT NULL,
  deleted_at TEXT NOT NULL,
  PRIMARY KEY(resource_type, resource_id, revision)
);
CREATE TRIGGER studio_audit_no_update BEFORE UPDATE ON studio_audit
BEGIN SELECT RAISE(ABORT, 'immutable_audit'); END;
CREATE TRIGGER studio_audit_no_delete BEFORE DELETE ON studio_audit
BEGIN SELECT RAISE(ABORT, 'immutable_audit'); END;
CREATE TRIGGER studio_tombstone_no_update BEFORE UPDATE ON studio_tombstones
BEGIN SELECT RAISE(ABORT, 'immutable_tombstone'); END;
CREATE TRIGGER studio_tombstone_no_delete BEFORE DELETE ON studio_tombstones
BEGIN SELECT RAISE(ABORT, 'immutable_tombstone'); END;
-- Fence pre-existing public identities without rewriting immutable publications.
-- Card authoring import from frozen manifests is separate from this SQL migration.
INSERT INTO studio_entities
SELECT 'topic', id, NULL, json_object('name', name),
  CASE WHEN deleted = 1 THEN 'deleted' WHEN published = 1 THEN 'active' ELSE 'hidden' END, revision
FROM catalog_topics;
INSERT INTO studio_entities
SELECT 'pack', id, topic_id, json_object('name', name, 'topicId', topic_id),
  CASE WHEN deleted = 1 THEN 'deleted' WHEN published = 1 THEN 'active' ELSE 'hidden' END, revision
FROM catalog_packs;
