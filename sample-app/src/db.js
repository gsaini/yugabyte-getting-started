import pg from 'pg';

const { Pool } = pg;

// node-postgres works against YugabyteDB out of the box because YSQL is
// wire-compatible with Postgres. For production, prefer the Yugabyte
// "smart driver" (@yugabytedb/pg) which load-balances across all tservers.
export const pool = new Pool({
  host:     process.env.PGHOST     || 'localhost',
  port:     Number(process.env.PGPORT) || 5433,
  user:     process.env.PGUSER     || 'yugabyte',
  password: process.env.PGPASSWORD || '',
  database: process.env.PGDATABASE || 'orders_app',
  max: 10,
});

// Retry wrapper for serialization failures (SQLSTATE 40001) — expected
// at Serializable isolation under contention.
export async function withRetry(fn, attempts = 5) {
  let lastErr;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (err) {
      if (err?.code !== '40001') throw err;
      lastErr = err;
      await new Promise(r => setTimeout(r, 50 * Math.pow(2, i)));
    }
  }
  throw lastErr;
}
