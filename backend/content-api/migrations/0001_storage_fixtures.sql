-- Infrastructure-only metadata. T19/T21 will define the content schema/contracts.
-- Binary bytes live in R2, never in D1. Applied once via Wrangler's migration ledger.
CREATE TABLE storage_fixtures (
  id TEXT PRIMARY KEY NOT NULL,
  object_key TEXT NOT NULL UNIQUE,
  sha256 TEXT NOT NULL CHECK(length(sha256) = 64 AND sha256 NOT GLOB '*[^0-9a-f]*'),
  byte_length INTEGER NOT NULL CHECK(byte_length > 0),
  content_type TEXT NOT NULL CHECK(content_type = 'image/webp')
);
