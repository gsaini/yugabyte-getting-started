import { pool } from './db.js';

const customers = [
  ['ada@example.com',   'Ada Lovelace'],
  ['alan@example.com',  'Alan Turing'],
  ['grace@example.com', 'Grace Hopper'],
];

const products = [
  ['BOOK-001', 'The Pragmatic Programmer', 39.95, 100],
  ['BOOK-002', 'Designing Data-Intensive Apps', 49.95, 80],
  ['TOY-001',  'Rubber Duck (debugging companion)', 5.99, 1000],
  ['HW-001',   'Mechanical Keyboard', 129.99, 25],
];

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    for (const [email, name] of customers) {
      await client.query(
        'INSERT INTO customers (email, name) VALUES ($1, $2) ON CONFLICT (email) DO NOTHING',
        [email, name],
      );
    }

    for (const [sku, name, price, stock] of products) {
      await client.query(
        'INSERT INTO products (sku, name, price, stock) VALUES ($1, $2, $3, $4) ON CONFLICT (sku) DO NOTHING',
        [sku, name, price, stock],
      );
    }

    await client.query('COMMIT');
    console.log(`Seeded ${customers.length} customers and ${products.length} products.`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
