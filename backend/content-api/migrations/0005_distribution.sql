-- Publications and Studio batches validate against the same administrative
-- generation so neither writer can overwrite changes validated by the other.
CREATE TABLE publication_commits (
  pack_id TEXT NOT NULL,
  revision INTEGER NOT NULL,
  expected_generation INTEGER NOT NULL,
  PRIMARY KEY(pack_id, revision)
);
CREATE TRIGGER publication_commit_guard BEFORE INSERT ON publication_commits
BEGIN
  SELECT CASE WHEN NEW.expected_generation != (SELECT generation FROM studio_generation WHERE id = 1)
    THEN RAISE(ABORT, 'publication_conflict') END;
END;
CREATE TRIGGER publication_commit_generation AFTER INSERT ON publication_commits
BEGIN UPDATE studio_generation SET generation = generation + 1 WHERE id = 1; END;
CREATE TRIGGER publication_administrative_revision BEFORE INSERT ON publication_revisions
BEGIN
  SELECT CASE WHEN EXISTS (SELECT 1 FROM studio_entities
    WHERE (resource_type = 'pack' AND id = NEW.pack_id AND
      (state IN ('deleted', 'purged') OR revision > NEW.revision))
      OR (resource_type = 'topic' AND id = NEW.topic_id AND state IN ('deleted', 'purged')))
    OR EXISTS (SELECT 1 FROM studio_tombstones WHERE resource_type = 'pack'
      AND resource_id = NEW.pack_id AND revision >= NEW.revision)
    THEN RAISE(ABORT, 'publication_conflict') END;
END;
CREATE TRIGGER publication_commit_no_update BEFORE UPDATE ON publication_commits
BEGIN SELECT RAISE(ABORT, 'immutable_publication'); END;
CREATE TRIGGER publication_commit_no_delete BEFORE DELETE ON publication_commits
BEGIN SELECT RAISE(ABORT, 'immutable_publication'); END;
-- A Card-level visibility change can temporarily suppress the old Pack snapshot.
-- A validated replacement resumes it only if no explicit Pack hide intervenes.
CREATE TABLE publication_suppression (
  pack_id TEXT PRIMARY KEY NOT NULL,
  resume_published INTEGER NOT NULL CHECK(resume_published IN (0, 1))
);
