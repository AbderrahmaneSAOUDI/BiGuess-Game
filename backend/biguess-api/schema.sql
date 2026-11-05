-- Game match records table
CREATE TABLE IF NOT EXISTS game_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    pack TEXT NOT NULL,
    winner TEXT NOT NULL,
    total_turns INTEGER NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast topic/pack queries
CREATE INDEX IF NOT EXISTS idx_records_topic_pack ON game_records(topic, pack);
