-- ============================================================
-- Exercise 2 — YCQL distributed transactions
-- ============================================================
-- This is the big differentiator vs. Cassandra: real ACID
-- transactions, not eventual consistency / LWT trickery.
-- ============================================================

USE iot;

-- A table that participates in transactions must be created
-- with transactional properties enabled.
CREATE TABLE inventory (
  product_id  UUID PRIMARY KEY,
  warehouse   TEXT,
  stock       INT
) WITH transactions = { 'enabled' : true };

INSERT INTO inventory (product_id, warehouse, stock)
  VALUES (uuid(), 'A', 100);
INSERT INTO inventory (product_id, warehouse, stock)
  VALUES (uuid(), 'B', 50);

-- ---- Distributed transaction across multiple rows ----
BEGIN TRANSACTION
  UPDATE inventory SET stock = stock - 10 WHERE product_id = <id-A>;
  UPDATE inventory SET stock = stock + 10 WHERE product_id = <id-B>;
END TRANSACTION;

SELECT * FROM inventory;

-- ---- Conditional writes ----
-- The classic compare-and-set, but here it's a real distributed CAS.
UPDATE inventory SET stock = stock - 5
  WHERE product_id = <id-A>
  IF stock >= 5;

-- ---- A multi-table transaction ----
CREATE TABLE orders (
  order_id    UUID PRIMARY KEY,
  product_id  UUID,
  qty         INT,
  status      TEXT
) WITH transactions = { 'enabled' : true };

BEGIN TRANSACTION
  UPDATE inventory SET stock = stock - 3 WHERE product_id = <id-A>;
  INSERT INTO orders (order_id, product_id, qty, status)
    VALUES (uuid(), <id-A>, 3, 'placed');
END TRANSACTION;
