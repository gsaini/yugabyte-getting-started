# 3. YSQL vs YCQL

YugabyteDB exposes **two query APIs**, both backed by the same DocDB storage layer. You can pick either (or both — they can coexist in one cluster, in different keyspaces).

## YSQL — PostgreSQL-compatible SQL

- Wire-compatible with **PostgreSQL 11+** (continually catching up to newer versions).
- Reuses the actual Postgres parser/planner — drop-in for most apps.
- Supports: joins, subqueries, CTEs, views, triggers, stored procedures, foreign keys, JSON, GIN/GiST indexes, extensions like `pgcrypto`, `uuid-ossp`.
- Talks the Postgres wire protocol on port **5433** (note: not 5432).
- Use any Postgres driver: `psycopg2`, `pgx`, `JDBC`, `node-postgres`, etc.

```sql
-- Looks and feels like Postgres
CREATE TABLE orders (
  id         UUID PRIMARY KEY,
  customer_id UUID NOT NULL,
  total      NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON orders (customer_id);
```

### What's different from vanilla Postgres
- **No** `WITH RECURSIVE`-heavy workloads on huge tables (works, but distributed cost).
- **No** sequences in the Postgres sense by default — use `UUID` or `serial`-like with caveats.
- DDL is **online** but more expensive than Postgres (it's a cluster-wide operation).
- `EXPLAIN` shows distributed plan nodes (`YB Seq Scan`, `Index Scan with RPC`, etc.).

## YCQL — Cassandra-compatible CQL

- Inspired by Cassandra's CQL but with **strong consistency and ACID transactions**.
- Good for: wide-column data, time-series, IoT, high-write workloads with simple access patterns.
- Talks CQL protocol on port **9042**.

```cql
CREATE KEYSPACE iot;

CREATE TABLE iot.sensor_readings (
  sensor_id  UUID,
  ts         TIMESTAMP,
  temp       DOUBLE,
  humidity   DOUBLE,
  PRIMARY KEY ((sensor_id), ts)
) WITH CLUSTERING ORDER BY (ts DESC);
```

### What YCQL gives you that Cassandra doesn't
- **Single-row ACID** by default (Cassandra is eventual).
- **Distributed transactions** with `BEGIN TRANSACTION; ... END TRANSACTION;`.
- **Secondary indexes** that are strongly consistent (Cassandra's are notoriously flaky).
- **JSONB** column type.

## Choosing between them

| Use case                                  | Pick   |
|-------------------------------------------|--------|
| Existing Postgres app, want to scale      | YSQL   |
| Complex joins / relational integrity      | YSQL   |
| Many-to-many relationships                | YSQL   |
| Wide-column / time-series / IoT          | YCQL   |
| Simple key → value(s) at massive scale    | YCQL   |
| Migrating off Cassandra                   | YCQL   |

> If unsure, **start with YSQL**. The Postgres ecosystem is bigger and you give up very little.

## Can I use both?

Yes — a single cluster can serve YSQL and YCQL simultaneously. They share storage but live in different keyspaces. Data in one is not directly visible to the other.

Next: [Sharding and replication →](04-sharding-replication.md)
