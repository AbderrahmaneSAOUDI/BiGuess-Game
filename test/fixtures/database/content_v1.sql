-- Frozen pre-index/tombstone schema for the v1 -> v2 upgrade test.
PRAGMA user_version = 1;
CREATE TABLE topics (
  id TEXT NOT NULL PRIMARY KEY CHECK(length(trim(id)) > 0),
  name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
  published INTEGER NOT NULL CHECK(published IN (0, 1)),
  deleted INTEGER NOT NULL CHECK(deleted IN (0, 1)),
  revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1)
);
CREATE TABLE packs (
  id TEXT NOT NULL PRIMARY KEY CHECK(length(trim(id)) > 0),
  topic_id TEXT NOT NULL REFERENCES topics(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
  published INTEGER NOT NULL CHECK(published IN (0, 1)),
  deleted INTEGER NOT NULL CHECK(deleted IN (0, 1)),
  revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1)
);
CREATE TABLE cards (
  id TEXT NOT NULL PRIMARY KEY CHECK(length(trim(id)) > 0),
  pack_id TEXT NOT NULL REFERENCES packs(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
  image_reference TEXT NOT NULL CHECK(length(image_reference) > 0 AND image_reference = trim(image_reference)),
  difficulty INTEGER NOT NULL CHECK(difficulty IN (1, 2, 3))
);
CREATE TABLE installed_packs (
  pack_id TEXT NOT NULL PRIMARY KEY REFERENCES packs(id) ON DELETE RESTRICT,
  revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1),
  installed_at INTEGER NOT NULL CHECK(typeof(installed_at) = 'integer' AND installed_at >= 0)
);
INSERT INTO topics VALUES ('topic', 'Étoiles 星', 0, 0, 2);
INSERT INTO packs VALUES ('pack', 'topic', 'Shapes', 0, 0, 3);
INSERT INTO cards VALUES ('card', 'pack', 'Square', 'assets/images/星/Square.webp', 1);
INSERT INTO installed_packs VALUES ('pack', 3, 1793919600000);
