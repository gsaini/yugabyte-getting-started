-- ============================================================
-- Exercise 3 — Indexes in YugabyteDB
-- ============================================================
-- Secondary indexes in Yugabyte are themselves distributed —
-- each index has its own tablets and Raft groups.
-- That means an index lookup is an extra RPC. Covering indexes
-- (INCLUDE) can eliminate that second hop.
-- ============================================================

\c learn_yb

-- A products table
CREATE TABLE products (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku         TEXT NOT NULL,
  category    TEXT NOT NULL,
  name        TEXT NOT NULL,
  price       NUMERIC(10,2) NOT NULL,
  stock       INT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Seed it
INSERT INTO products (sku, category, name, price, stock)
SELECT
  'SKU-' || i,
  (ARRAY['books','toys','clothing','home','grocery'])[1 + (i % 5)],
  'Product ' || i,
  (random() * 200)::NUMERIC(10,2),
  (random() * 1000)::INT
FROM generate_series(1, 10000) i;

-- ---- 1. Plain secondary index ----
CREATE INDEX idx_products_category ON products (category);

-- This will use the index, but does 2 RPCs:
--   (a) look up matching IDs in the index tablet
--   (b) fetch the row from the table tablet
EXPLAIN (ANALYZE, DIST)
SELECT name, price FROM products WHERE category = 'books' LIMIT 10;

-- ---- 2. Covering index (eliminates the second RPC) ----
CREATE INDEX idx_products_cat_covering
  ON products (category) INCLUDE (name, price);

-- Same query: now 1 RPC, served entirely from the index
EXPLAIN (ANALYZE, DIST)
SELECT name, price FROM products WHERE category = 'books' LIMIT 10;

-- ---- 3. Unique index ----
CREATE UNIQUE INDEX idx_products_sku ON products (sku);

-- ---- 4. Multi-column index for compound queries ----
CREATE INDEX idx_products_cat_price ON products (category, price DESC);

EXPLAIN (ANALYZE, DIST)
SELECT name, price
FROM products
WHERE category = 'toys'
ORDER BY price DESC
LIMIT 20;

-- ---- See all indexes ----
\di
