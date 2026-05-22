-- ============================================================
-- Exercise 4 — Distributed transactions
-- ============================================================
-- Open two ysqlsh sessions side-by-side to see the contention
-- and locking behavior. Comments below explain when to do that.
-- ============================================================

\c learn_yb

CREATE TABLE accounts (
  id       INT PRIMARY KEY,
  owner    TEXT NOT NULL,
  balance  NUMERIC(12,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES
  (1, 'Alice', 1000.00),
  (2, 'Bob',   1000.00),
  (3, 'Carol', 1000.00);

-- ---- A simple ACID transfer ----
BEGIN;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

SELECT * FROM accounts ORDER BY id;

-- ---- Isolation levels ----
-- Default is Read Committed (matches Postgres).
SHOW default_transaction_isolation;

-- Repeatable Read: whole txn sees one snapshot.
BEGIN ISOLATION LEVEL REPEATABLE READ;
  SELECT balance FROM accounts WHERE id = 1;
  -- (open session #2, change account 1, commit there)
  SELECT balance FROM accounts WHERE id = 1;  -- you still see the OLD value
COMMIT;

-- Serializable: as-if one-at-a-time. Conflicts -> SQLSTATE 40001.
BEGIN ISOLATION LEVEL SERIALIZABLE;
  SELECT balance FROM accounts WHERE id = 1;
  -- If session #2 also reads & writes id=1 and commits first,
  -- this txn will fail at COMMIT and you must retry.
  UPDATE accounts SET balance = balance + 1 WHERE id = 1;
COMMIT;

-- ---- Pessimistic locking with FOR UPDATE ----
-- In one session:
BEGIN;
  SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
  -- A concurrent session trying to update id=1 will WAIT
  -- until this transaction commits or rolls back.
  UPDATE accounts SET balance = balance - 50 WHERE id = 1;
COMMIT;

-- ---- Retry pattern (pseudocode for your app) ----
-- for attempt in 1..N:
--   try:
--     BEGIN ISOLATION LEVEL SERIALIZABLE;
--     ... statements ...
--     COMMIT;
--     break
--   except 40001 SerializationFailure:
--     sleep(2^attempt * 50ms)  -- exponential backoff
