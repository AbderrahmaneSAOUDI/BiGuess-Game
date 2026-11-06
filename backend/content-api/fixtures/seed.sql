-- Deterministic local-only fixture; re-running does not create duplicates.
INSERT INTO storage_fixtures (id, object_key, sha256, byte_length, content_type)
VALUES ('fixture-image-v1', 'fixtures/999ce566e4388b580be9f1e8b94c51616b949fe8152eb7c4c71869fd0cbf307e.webp', '999ce566e4388b580be9f1e8b94c51616b949fe8152eb7c4c71869fd0cbf307e', 38, 'image/webp')
ON CONFLICT(id) DO UPDATE SET object_key=excluded.object_key, sha256=excluded.sha256,
byte_length=excluded.byte_length, content_type=excluded.content_type;
