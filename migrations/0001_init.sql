-- NYIT Pool — initial D1 schema (Table Queue placeholder)
-- Apply with: npm run db:migrate:local   (local dev)
--             npm run db:migrate         (remote/production)

CREATE TABLE IF NOT EXISTS queue_entries (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  team_name  TEXT    NOT NULL,
  players    TEXT    NOT NULL DEFAULT '',            -- 'Alice · Bob'
  status     TEXT    NOT NULL DEFAULT 'waiting',    -- waiting | playing | done
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_queue_status
  ON queue_entries (status, created_at);
