-- NYIT Pool — audit log for the admin page (queue/admin actions, votes, match lifecycle)

CREATE TABLE IF NOT EXISTS audit_log (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  at           INTEGER NOT NULL,
  type         TEXT NOT NULL,     -- register | queue_join | queue_leave | teammate | skip_vote | party_skipped |
                                  -- queue_mode | queue_config | queue_wipe | match_submit | match_confirm |
                                  -- match_dispute | match_commit | admin_approve
  actor_user_id INTEGER REFERENCES users(id),  -- null = system/admin
  detail       TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_audit_at ON audit_log (at DESC);
