-- ============================================================
-- Exercise 1 — YSQL basics
-- ============================================================
-- Goal: get comfortable with the Postgres-compatible API.
-- Everything here works in vanilla Postgres too — that's the point.
-- ============================================================

-- Where am I?
SELECT version();          -- shows Postgres version Yugabyte emulates
SELECT current_database(); -- default is 'yugabyte'

-- ---- Create a database ----
CREATE DATABASE learn_yb;
\c learn_yb

-- ---- Create some tables ----
CREATE TABLE customers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT UNIQUE NOT NULL,
  name        TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE orders (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id  UUID NOT NULL REFERENCES customers(id),
  total        NUMERIC(10,2) NOT NULL,
  status       TEXT NOT NULL DEFAULT 'pending',
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- ---- Insert some data ----
INSERT INTO customers (email, name) VALUES
  ('ada@example.com', 'Ada Lovelace'),
  ('alan@example.com', 'Alan Turing'),
  ('grace@example.com', 'Grace Hopper');

INSERT INTO orders (customer_id, total, status)
SELECT id, 49.99, 'paid' FROM customers WHERE email = 'ada@example.com';

INSERT INTO orders (customer_id, total, status)
SELECT id, 19.50, 'pending' FROM customers WHERE email = 'alan@example.com';

-- ---- Read it back ----
SELECT c.name, o.total, o.status, o.created_at
FROM customers c
JOIN orders o ON o.customer_id = c.id
ORDER BY o.created_at;

-- ---- Update + Delete ----
UPDATE orders SET status = 'shipped' WHERE status = 'paid';
DELETE FROM orders WHERE status = 'pending';

-- ---- Inspect the schema ----
\dt
\d customers
\d orders

-- Cleanup if you want a clean slate:
-- DROP DATABASE learn_yb;
