# 2. Architecture Overview

YugabyteDB is built as **two layers**: a stateless query layer that speaks SQL/CQL, and a stateful distributed storage layer.

```
        ┌────────────────────────────────────────────────┐
        │  Query Layer  (YQL)                            │
        │  ┌──────────────┐        ┌──────────────┐     │
        │  │  YSQL        │        │  YCQL        │     │
        │  │ (Postgres)   │        │ (Cassandra)  │     │
        │  └──────────────┘        └──────────────┘     │
        ├────────────────────────────────────────────────┤
        │  Storage Layer  (DocDB)                        │
        │  - Sharded, replicated, transactional KV store │
        │  - RocksDB on each node                        │
        │  - Raft consensus per shard (tablet)           │
        └────────────────────────────────────────────────┘
```

## The two server processes

A YugabyteDB cluster is made up of **two kinds of processes** running on each node:

### YB-Master
- Cluster metadata service.
- Tracks where every tablet lives, handles DDL, coordinates load-balancing.
- Runs as a small Raft group (typically 3 masters across zones).
- *Not* on the hot path for reads/writes.

### YB-TServer (Tablet Server)
- Stores actual data — owns a set of **tablets** (shards).
- Handles all reads and writes.
- Runs the query layer (YSQL/YCQL) and the storage engine (DocDB) in the same process.
- You scale by adding more TServers.

> Rule of thumb: 1 YB-Master + 1 YB-TServer per node in dev. In prod, 3 masters cluster-wide and 1 TServer per node.

## Tablets — the unit of distribution

Every table is automatically split into **tablets** (default: 1 per CPU core per node, configurable). A tablet is:

- A contiguous range or hash range of the table's primary key.
- Replicated to **Replication Factor (RF) = 3** by default — one leader, two followers.
- Has its own **Raft group** for consensus.

This is why Yugabyte scales: throughput is the sum of throughput across all tablet leaders, spread across all nodes.

## DocDB — the storage engine

DocDB is Yugabyte's custom distributed document store. Each TServer runs an instance of DocDB, which in turn uses a **modified RocksDB** for on-disk storage. Key features:

- **Document model** — rows are stored as documents keyed by primary key.
- **MVCC** — every write gets a Hybrid Logical Clock (HLC) timestamp; old versions are kept for snapshot isolation.
- **Raft per tablet** — writes go to the tablet leader, which replicates to followers before acking.

## Read/write path (simplified)

**Write:**
1. Client sends `INSERT` to any TServer.
2. Query layer parses, plans, and identifies target tablet(s).
3. Request is forwarded to the **tablet leader**.
4. Leader writes to its Raft log, replicates to followers.
5. Once a majority (2/3) ack, the write commits and the client is acknowledged.

**Read:**
1. Client sends `SELECT` to any TServer.
2. Query layer plans the query — single-tablet or distributed scan.
3. By default reads go to the **leader** (strongly consistent).
4. Follower reads are configurable for lower latency at slightly relaxed consistency.

## Failure handling

- TServer dies → its tablet *leaders* are re-elected on followers within seconds. No data loss because writes were already replicated.
- YB-Master dies → another master is elected; client connections are unaffected.
- Entire zone dies → cluster keeps serving from remaining zones if RF allows it (RF=3 across 3 zones tolerates 1 zone loss).

Next: [YSQL vs YCQL →](03-ysql-vs-ycql.md)
