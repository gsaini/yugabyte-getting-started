-- ============================================================
-- Exercise 2 — Sharding: HASH vs RANGE primary keys
-- ============================================================
-- This is the most important Yugabyte-specific concept.
-- Your PK choice determines how data is distributed and what
-- query patterns are fast.
-- ============================================================

\c learn_yb

-- ---- A hash-sharded table (default) ----
-- Hash is good for uniform write/read distribution.
-- Range scans on the hashed column are spread across all tablets.
CREATE TABLE events_hash (
  user_id  UUID,
  ts       TIMESTAMPTZ,
  event    TEXT,
  PRIMARY KEY ((user_id) HASH, ts ASC)
) SPLIT INTO 8 TABLETS;

-- ---- A range-sharded table ----
-- Range is good for time-series scans, but a monotonically increasing
-- key (like wall-clock ts) creates a "hot tablet" problem.
CREATE TABLE events_range (
  ts       TIMESTAMPTZ,
  user_id  UUID,
  event    TEXT,
  PRIMARY KEY (ts ASC, user_id ASC)
);

-- ---- Insert sample data into both ----
INSERT INTO events_hash (user_id, ts, event)
SELECT gen_random_uuid(), now() - (i * interval '1 minute'), 'click'
FROM generate_series(1, 1000) AS i;

INSERT INTO events_range (ts, user_id, event)
SELECT now() - (i * interval '1 minute'), gen_random_uuid(), 'click'
FROM generate_series(1, 1000) AS i;

-- ---- Compare query plans ----
-- Fast: equality on the hash column hits one tablet
EXPLAIN (ANALYZE, DIST) SELECT * FROM events_hash WHERE user_id = gen_random_uuid();

-- Slow on hash: a range scan must hit every tablet
EXPLAIN (ANALYZE, DIST) SELECT * FROM events_hash WHERE ts > now() - interval '1 hour';

-- Fast on range: a contiguous tablet range
EXPLAIN (ANALYZE, DIST) SELECT * FROM events_range WHERE ts > now() - interval '1 hour';

-- ---- See where tablets actually live ----
SELECT * FROM yb_servers();

-- ---- A better design for time-series ----
-- Hash on the entity (user_id), range on time within that entity.
-- Per-user scans are local; the global distribution stays uniform.
CREATE TABLE events_best (
  user_id  UUID,
  ts       TIMESTAMPTZ,
  event    TEXT,
  PRIMARY KEY ((user_id) HASH, ts DESC)
) SPLIT INTO 8 TABLETS;
