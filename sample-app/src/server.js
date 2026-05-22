import Fastify from 'fastify';
import { pool, withRetry } from './db.js';

const app = Fastify({ logger: true });

app.get('/health', async () => {
  const r = await pool.query('SELECT 1 AS ok');
  return { ok: r.rows[0].ok === 1 };
});

app.get('/customers', async () => {
  const r = await pool.query(
    'SELECT id, email, name, created_at FROM customers ORDER BY created_at DESC LIMIT 100',
  );
  return r.rows;
});

app.get('/products', async () => {
  const r = await pool.query(
    'SELECT id, sku, name, price, stock FROM products ORDER BY sku',
  );
  return r.rows;
});

// Place an order — demonstrates a multi-table distributed transaction
// with row-level locking on the product stock and a retry on serialization
// failure. This is the YugabyteDB equivalent of "the classic 4-table txn."
app.post('/orders', async (req, reply) => {
  const { customer_id, items } = req.body || {};
  if (!customer_id || !Array.isArray(items) || items.length === 0) {
    return reply.code(400).send({ error: 'customer_id and items[] required' });
  }

  const result = await withRetry(async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN ISOLATION LEVEL SERIALIZABLE');

      const orderRes = await client.query(
        `INSERT INTO orders (customer_id, total)
         VALUES ($1, 0) RETURNING id`,
        [customer_id],
      );
      const orderId = orderRes.rows[0].id;

      let total = 0;
      for (const { product_id, qty } of items) {
        const prod = await client.query(
          'SELECT price, stock FROM products WHERE id = $1 FOR UPDATE',
          [product_id],
        );
        if (prod.rowCount === 0) throw new Error(`product ${product_id} not found`);
        const { price, stock } = prod.rows[0];
        if (stock < qty) throw new Error(`insufficient stock for ${product_id}`);

        await client.query(
          'UPDATE products SET stock = stock - $1 WHERE id = $2',
          [qty, product_id],
        );
        await client.query(
          `INSERT INTO order_items (order_id, product_id, qty, unit_price)
           VALUES ($1, $2, $3, $4)`,
          [orderId, product_id, qty, price],
        );
        total += Number(price) * qty;
      }

      await client.query(
        'UPDATE orders SET total = $1 WHERE customer_id = $2 AND id = $3',
        [total.toFixed(2), customer_id, orderId],
      );

      await client.query('COMMIT');
      return { order_id: orderId, total };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  });

  return result;
});

app.get('/orders/:customerId', async (req) => {
  const r = await pool.query(
    `SELECT id, total, status, created_at
     FROM orders WHERE customer_id = $1
     ORDER BY created_at DESC`,
    [req.params.customerId],
  );
  return r.rows;
});

const port = Number(process.env.PORT) || 3000;
app.listen({ port, host: '0.0.0.0' }).catch(err => {
  app.log.error(err);
  process.exit(1);
});
