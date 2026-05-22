# 6. Performance & Tuning

Yugabyte's performance hinges on two things: **how data is laid out across tablets**, and **how queries map to tablet RPCs**. Get those right and most other tuning is incremental.

## The first thing to look at: schema design

### Choose the right primary key
Hash-sharded PKs distribute evenly but kill range scans. Range-sharded PKs enable scans but risk hot spots. Use composite PKs to get the best of both:

```sql
-- BAD for an IoT firehose — single hot tablet on the latest timestamp
PRIMARY KEY (ts ASC, sensor_id)

-- GOOD — hash by sensor_id, range by ts within each sensor
PRIMARY KEY ((sensor_id) HASH, ts DESC)
```

### Pre-split large tables
Don't wait for auto-splits if you know the table will be large:

```sql
CREATE TABLE events (...) SPLIT INTO 48 TABLETS;
```

A rule of thumb: ~1–2 tablets per CPU core in the cluster.

### Colocate small tables
A 3-row `currencies` lookup table doesn't need 16 tablets. Put it in a colocated DB or mark the table colocated:

```sql
CREATE TABLE currencies (...) WITH (colocation = true);
```

## Index strategy

- Yugabyte indexes are **distributed** — they have their own tablets and Raft groups. An index lookup is an extra RPC.
- **Covering indexes** (`INCLUDE`) avoid a second RPC to fetch the row:

```sql
CREATE INDEX ON orders (customer_id) INCLUDE (total, created_at);
```

- For frequently filtered + sorted queries, mirror the PK strategy: hash on the equality column, range on the order-by column.

## Query patterns to favor

- **Single-tablet queries** — driven by the full PK or its hash portion.
- **Batch operations** — `INSERT ... VALUES (...), (...), (...)` is much faster than N round trips.
- **Prepared statements** — saves parse/plan time across the cluster.

## Query patterns to avoid

- Unfiltered `SELECT *` on a giant hash-sharded table — every tablet has to be scanned.
- `OFFSET` for pagination on large tables — use keyset pagination instead.
- Sequential scans where an index would do.

## Diagnostics

### EXPLAIN ANALYZE
Like Postgres, but distributed:

```sql
EXPLAIN (ANALYZE, DIST, VERBOSE) SELECT ... ;
```

The `DIST` option (Yugabyte-specific) shows per-tablet RPC counts. Watch for:
- High `Read RPC count` → query is hitting many tablets unnecessarily.
- Sequential scan where you expected an index scan.

### Admin UI
- `http://<any-node>:7000` — master UI. Tablet distribution, leader counts, replication state.
- `http://<any-node>:9000` — tserver UI. Per-tablet metrics, slow queries.

### `pg_stat_statements`
Standard Postgres view, works in YSQL. Find your worst queries:

```sql
SELECT query, calls, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 20;
```

## Connection management

- Yugabyte ships with a **smart driver** for several languages (Java, Go, Python, Node). The smart driver discovers all TServers and load-balances client connections — use it.
- Otherwise, put **PgBouncer** or **YB's built-in connection manager** in front to avoid per-connection overhead.

## Memory & disk tuning (production)

- Give YB-TServer **at least 16 GB RAM**, more for write-heavy workloads.
- SSD storage. NVMe is best.
- Separate **WAL** and **data** disks if possible (`--fs_wal_dirs` / `--fs_data_dirs`).
- Bump `--memstore_size_mb` for write-heavy clusters.

## Read-after-write & consistency knobs

| Goal                                | Setting |
|-------------------------------------|---------|
| Lowest latency, accept stale reads  | `yb_read_from_followers = true` |
| Strong consistency (default)        | leader reads, RF=3 |
| Read-only analytics replica         | xCluster async replication to a separate cluster |
| Bounded staleness                   | `yb_follower_read_staleness_ms = N` |

## What "good" looks like (rule of thumb)

For a healthy small cluster (3 nodes, RF=3, modest hardware):
- Point read / write: **1–3 ms** intra-AZ.
- Cross-AZ write: **5–15 ms**.
- Cross-region write (e.g. US-East ↔ EU): **70–150 ms** — physics, not Yugabyte.

If your numbers are far worse, the problem is almost always one of:
1. A poor primary key (hot tablet).
2. Sequential scans where an index should exist.
3. A long-running transaction holding provisional records.

Next: [Setup guide →](../setup/README.md)
