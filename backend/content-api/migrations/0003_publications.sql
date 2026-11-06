-- A row exists only after every immutable R2 artifact has been verified.
CREATE TABLE publication_topics (
  topic_id TEXT PRIMARY KEY NOT NULL,
  available INTEGER NOT NULL DEFAULT 1 CHECK (available IN (0, 1))
);
CREATE TABLE publication_heads (
  pack_id TEXT PRIMARY KEY NOT NULL,
  topic_id TEXT NOT NULL REFERENCES publication_topics(topic_id),
  revision INTEGER NOT NULL,
  previous_revision INTEGER,
  available INTEGER NOT NULL DEFAULT 1 CHECK (available IN (0, 1))
);
CREATE TABLE publication_revisions (
  pack_id TEXT NOT NULL,
  topic_id TEXT NOT NULL REFERENCES publication_topics(topic_id),
  revision INTEGER NOT NULL CHECK (revision > 0 AND revision <= 9007199254740991),
  expected_revision INTEGER NOT NULL CHECK (expected_revision >= 0),
  receipt TEXT NOT NULL CHECK (json_valid(receipt)),
  PRIMARY KEY (pack_id, revision)
);
CREATE TRIGGER publication_precondition BEFORE INSERT ON publication_revisions
BEGIN
  SELECT CASE WHEN NEW.expected_revision != COALESCE(
    (SELECT revision FROM publication_heads WHERE pack_id = NEW.pack_id), 0)
    OR NEW.revision <= NEW.expected_revision
    OR EXISTS (SELECT 1 FROM publication_heads WHERE pack_id = NEW.pack_id AND topic_id != NEW.topic_id)
    OR EXISTS (SELECT 1 FROM catalog_packs WHERE id = NEW.pack_id
      AND (topic_id != NEW.topic_id OR revision != NEW.expected_revision))
    THEN RAISE(ABORT, 'publication_conflict') END;
END;
CREATE TRIGGER publication_activate AFTER INSERT ON publication_revisions
BEGIN
  INSERT INTO publication_heads (pack_id, topic_id, revision, previous_revision)
  VALUES (NEW.pack_id, NEW.topic_id, NEW.revision, NULLIF(NEW.expected_revision, 0))
  ON CONFLICT(pack_id) DO UPDATE SET
    previous_revision = publication_heads.revision, revision = NEW.revision;
END;
-- Receipt/history are immutable. Rollback means publish old content at a NEW revision.
CREATE TRIGGER publication_no_update BEFORE UPDATE ON publication_revisions
BEGIN SELECT RAISE(ABORT, 'immutable_publication'); END;
CREATE TRIGGER publication_no_delete BEFORE DELETE ON publication_revisions
BEGIN SELECT RAISE(ABORT, 'immutable_publication'); END;
