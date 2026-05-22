# Cheatsheet

Day-to-day commands and SQL patterns you'll reach for the most.

## Shell access

```bash
# YSQL (Postgres-compatible)
docker exec -it yugabyte ysqlsh -h yugabyte
psql -h localhost -p 5433 -U yugabyte

# YCQL (Cassandra-compatible)
docker exec -it yugabyte ycqlsh yugabyte
```

## Cluster info

```sql
SELECT version();
SELECT * FROM yb_servers();                            -- nodes and IPs
SELECT * FROM yb_table_properties('orders'::regclass); -- tablet count, RF
SHOW yb_read_from_followers;
```

## Common YSQL patterns

```sql
-- Hash-sharded PK (default, even distribution)
PRIMARY KEY ((customer_id) HASH, id ASC)

-- Range-sharded PK (good for ordered scans)
PRIMARY KEY (ts ASC, id ASC)

-- Pre-split a large table
CREATE TABLE big (...) SPLIT INTO 16 TABLETS;

-- Covering index — avoids the second RPC
CREATE INDEX idx ON t (a) INCLUDE (b, c);

-- Colocate small tables in one tablet
CREATE DATABASE small_app WITH COLOCATED = true;
CREATE TABLE lookup (...) WITH (colocation = true);
```

## Transactions

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
  SELECT ... FOR UPDATE;     -- pessimistic lock
  UPDATE ...;
COMMIT;

-- On 40001 SerializationFailure: retry with exponential backoff
```

## Performance diagnosis

```sql
EXPLAIN (ANALYZE, DIST, VERBOSE) SELECT ...;

SELECT substring(query,1,80), calls, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 10;

SELECT pid, state, substring(query,1,60)
FROM pg_stat_activity WHERE state != 'idle';
```

## Follower reads (lower-latency, slightly stale)

```sql
SET yb_read_from_followers = true;
SET default_transaction_read_only = true;
SET yb_follower_read_staleness_ms = 30000;
```

## Useful Yugabyte-specific functions

| Function                              | What it does |
|---------------------------------------|--------------|
| `yb_servers()`                        | All nodes + zones |
| `yb_table_properties('t'::regclass)`  | Tablet count, RF, colocation |
| `yb_hash_code(...)`                   | Compute the hash bucket for a row |
| `yb_is_local_table(oid)`              | Is this table colocated? |

## Useful YCQL bits

```cql
CREATE KEYSPACE k;
CREATE TABLE t (... PRIMARY KEY ((pk), ck))
  WITH transactions = { 'enabled' : true }
   AND CLUSTERING ORDER BY (ck DESC)
   AND default_time_to_live = 86400;

BEGIN TRANSACTION
  UPDATE ...;
  INSERT ...;
END TRANSACTION;
```

## Admin UIs

| URL                       | What you see |
|---------------------------|--------------|
| http://localhost:7000     | Master: cluster state, tablets, leaders |
| http://localhost:9000     | TServer: per-node metrics, slow queries |
| http://localhost:15433    | yugabyted dashboard (if used) |
