# 4. Sharding & Replication

This is where Yugabyte differs most from single-node Postgres. Understanding **tablets** and **Raft groups** is the key to reasoning about performance and consistency.

## Tablets — automatic sharding

A **tablet** is a shard of a table. When you create a table, Yugabyte automatically splits it into multiple tablets distributed across TServers.

Two sharding strategies:

### Hash sharding (default in YSQL & YCQL)
- Primary key is **hashed**; rows are bucketed into tablets by hash range.
- Pro: uniform distribution, no hot tablets.
- Con: range scans on the hashed column are scattered across all tablets.

```sql
-- Hash sharded on (customer_id) — the HASH keyword is explicit
CREATE TABLE orders (
  customer_id UUID,
  order_id    UUID,
  total       NUMERIC,
  PRIMARY KEY ((customer_id) HASH, order_id ASC)
);
```

### Range sharding
- Tablets are split by **key range** (like Postgres partitioning, but automatic).
- Good for time-series / monotonically-increasing keys you want to scan in order.
- Risk: hot tablet on the latest range — mitigate with composite PKs.

```sql
CREATE TABLE events (
  ts    TIMESTAMPTZ,
  id    UUID,
  data  JSONB,
  PRIMARY KEY (ts ASC, id ASC)
);
```

## Tablet splitting

Tablets auto-split when they grow beyond a threshold (default ~10GB). You can also pre-split at table creation:

```sql
CREATE TABLE big_table (
  id UUID PRIMARY KEY
) SPLIT INTO 16 TABLETS;
```

Pre-splitting matters for tables you expect to be large from day one — it avoids the slow ramp-up while auto-splits happen.

## Replication & Raft

Every tablet is replicated to **RF (replication factor)** copies, default 3.

```
           Tablet T1
   ┌────────────────────────┐
   │  Leader  →  Node A     │
   │  Follower → Node B     │
   │  Follower → Node C     │
   └────────────────────────┘
        (Raft group)
```

Each tablet runs its own Raft consensus group:

1. Writes go to the **leader**.
2. Leader appends to its Raft log, replicates to followers.
3. Once **majority (RF/2 + 1)** persist, the write is committed.
4. Client gets the ack.

This is what gives Yugabyte its **strong consistency** without sacrificing availability — losing any minority of replicas is fine.

## Replication factor and zone awareness

Typical deployments:
- **RF=3 in one region across 3 AZs** — survives 1 AZ outage. Most common.
- **RF=5 across 3 regions** — survives 1 region + 1 AZ. Higher write latency.
- **RF=1** — single node, dev only. No HA.

Yugabyte is **rack-aware / zone-aware** — the placement policy ensures replicas of a tablet land in *different* failure domains.

## Leader balancing

If one node accidentally hosts most leaders, that node becomes a bottleneck. The cluster runs a **leader balancer** that periodically redistributes leadership so each TServer carries roughly equal leader load.

## Colocation — opt out of sharding

For small tables (lookup tables, config, small tenant data), sharding adds overhead. Yugabyte supports **colocated databases**: all tables in the DB share **one tablet**, so joins become local.

```sql
CREATE DATABASE small_app WITH COLOCATED = true;
```

Use colocation when:
- The total DB will stay small (under a few GB).
- You join frequently between tables.
- You want Postgres-like performance for small workloads.

Avoid colocation for any table that will grow large — you lose horizontal scaling.

## Tablet ↔ Region inspection

```sql
-- View tablets and where they live
SELECT * FROM yb_servers();
SELECT * FROM yb_table_properties('orders'::regclass);
```

The admin UI on **http://localhost:7000** shows every tablet, its leader, followers, and per-tablet stats.

Next: [Distributed transactions →](05-transactions.md)
