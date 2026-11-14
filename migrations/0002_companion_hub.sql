-- NYIT Pool — Companion Hub schema (auth, queue parties, skip votes,
-- match confirmation inbox, Glicko-2 ratings).
-- 0001 is already applied in production, so this ships as a new migration.

-- Registered players (mobile companion accounts)
CREATE TABLE IF NOT EXISTS users (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  username       TEXT    NOT NULL UNIQUE,           -- lowercase normalized
  nickname       TEXT    NOT NULL,
  pin_hash       TEXT    NOT NULL,                  -- PBKDF2-SHA256 (b64)
  pin_salt       TEXT    NOT NULL,                  -- random 16B (b64)
  glicko_rating  REAL    NOT NULL DEFAULT 1500.0,
  glicko_rd      REAL    NOT NULL DEFAULT 350.0,
  glicko_vol     REAL    NOT NULL DEFAULT 0.06,
  ranked_wins    INTEGER NOT NULL DEFAULT 0,
  ranked_losses  INTEGER NOT NULL DEFAULT 0,
  casual_wins    INTEGER NOT NULL DEFAULT 0,
  casual_losses  INTEGER NOT NULL DEFAULT 0,
  last_played_at INTEGER,
  created_at     INTEGER NOT NULL
);

-- Queue parties: a party is a TEAM. 'solo' = one player, 'duo' = one or two
-- players (P2 can be attached later or claimed while waiting).
CREATE TABLE IF NOT EXISTS queue_parties (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  format           TEXT    NOT NULL CHECK (format IN ('solo', 'duo')),
  status           TEXT    NOT NULL DEFAULT 'waiting'
                   CHECK (status IN ('waiting', 'playing', 'completed', 'skipped')),
  created_by_user_id INTEGER NOT NULL REFERENCES users(id),
  p1_user_id       INTEGER REFERENCES users(id),
  p1_guest_name    TEXT,
  p2_user_id       INTEGER REFERENCES users(id),
  p2_guest_name    TEXT,
  position         INTEGER NOT NULL,
  created_at       INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_parties_active ON queue_parties (status, position);
DROP TABLE IF EXISTS queue_entries;   -- placeholder table from the pre-auth queue

-- 3-vote consensus skip (one vote per account per party)
CREATE TABLE IF NOT EXISTS skip_votes (
  party_id      INTEGER NOT NULL REFERENCES queue_parties(id) ON DELETE CASCADE,
  voter_user_id INTEGER NOT NULL REFERENCES users(id),
  created_at    INTEGER NOT NULL,
  PRIMARY KEY (party_id, voter_user_id)
);

-- Matches awaiting unanimous confirmation
CREATE TABLE IF NOT EXISTS pending_matches (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  match_type           TEXT NOT NULL CHECK (match_type IN ('ranked', 'casual')),
  format               TEXT NOT NULL CHECK (format IN ('1v1', '2v2', '2v1')),
  winner_team          INTEGER NOT NULL CHECK (winner_team IN (1, 2)),
  submitted_by_user_id INTEGER NOT NULL REFERENCES users(id),
  status               TEXT NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'disputed', 'approved', 'rejected')),
  created_at           INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS pending_match_players (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  pending_match_id INTEGER NOT NULL REFERENCES pending_matches(id) ON DELETE CASCADE,
  team             INTEGER NOT NULL CHECK (team IN (1, 2)),
  user_id          INTEGER REFERENCES users(id),
  guest_name       TEXT,
  confirmed        INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_pmp_user ON pending_match_players (user_id, confirmed);

-- Committed match history (immutable)
CREATE TABLE IF NOT EXISTS matches (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  match_type   TEXT    NOT NULL CHECK (match_type IN ('ranked', 'casual')),
  format       TEXT    NOT NULL CHECK (format IN ('1v1', '2v2', '2v1')),
  winner_team  INTEGER NOT NULL CHECK (winner_team IN (1, 2)),
  rating_delta REAL,                    -- mean rating change (ranked only)
  played_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS match_players (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  match_id   INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  team       INTEGER NOT NULL CHECK (team IN (1, 2)),
  user_id    INTEGER REFERENCES users(id),
  guest_name TEXT
);
CREATE INDEX IF NOT EXISTS idx_mp_user ON match_players (user_id);
