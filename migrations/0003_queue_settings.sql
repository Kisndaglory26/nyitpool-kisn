-- NYIT Pool — admin queue-mode override storage.
-- No row = 'auto' (time windows decide). Admin sets 'open' | 'duo-only' | 'offline' via
-- POST /api/admin/queue-mode (X-Admin-Pin), or clears back to auto.

CREATE TABLE IF NOT EXISTS queue_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
