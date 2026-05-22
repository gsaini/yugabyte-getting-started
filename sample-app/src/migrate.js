import { pool } from './db.js';

const SCHEMA = `
  CREATE TABLE IF NOT EXISTS customers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT UNIQUE NOT NULL,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
  );

  CREATE TABLE IF NOT EXISTS products (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku         TEXT UNIQUE NOT NULL,
    name        TEXT NOT NULL,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock       INT NOT NULL CHECK (stock >= 0)
  );

  -- Hash-sharded on customer_id so a single customer's orders live together.
  CREATE TABLE IF NOT EXISTS orders (
    id           UUID DEFAULT gen_random_uuid(),
    customer_id  UUID NOT NULL REFERENCES customers(id),
    total        NUMERIC(12,2) NOT NULL,
    status       TEXT NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY ((customer_id) HASH, id)
  );

  CREATE TABLE IF NOT EXISTS order_items (
    order_id     UUID NOT NULL,
    product_id   UUID NOT NULL REFERENCES products(id),
    qty          INT NOT NULL CHECK (qty > 0),
    unit_price   NUMERIC(10,2) NOT NULL,
    PRIMARY KEY ((order_id) HASH, product_id)
  );

  CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders (status) INCLUDE (customer_id, total, created_at);
`;

async function run() {
  console.log('Applying schema to YugabyteDB...');
  await pool.query(SCHEMA);
  console.log('Done.');
  await pool.end();
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
