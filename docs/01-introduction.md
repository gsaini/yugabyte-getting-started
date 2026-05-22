# 1. What is YugabyteDB?

YugabyteDB is an **open-source, distributed SQL database** designed to be:

- **PostgreSQL-compatible** — you reuse the same SQL syntax, drivers, frameworks, and tooling you already know
- **Horizontally scalable** — add nodes and the cluster automatically rebalances data
- **Resilient** — survives node, zone, and even region failures with no data loss
- **Geo-distributed** — supports multi-region deployments with tunable consistency

It is sometimes described as "Spanner-like, but open source, and speaks Postgres."

## Where it sits in the database landscape

| Property                 | Traditional RDBMS (Postgres, MySQL) | NoSQL (Cassandra, Mongo) | YugabyteDB        |
|--------------------------|--------------------------------------|--------------------------|-------------------|
| SQL & joins              | Yes                                  | Limited / no             | Yes               |
| ACID transactions        | Yes (single node)                    | Eventual / weak          | Yes (distributed) |
| Horizontal scaling       | Hard (sharding bolt-on)              | Easy                     | Built-in          |
| HA without external tools| No                                   | Yes                      | Yes               |
| Postgres ecosystem       | Yes                                  | No                       | Yes               |

## When YugabyteDB is a good fit

- You're outgrowing single-node Postgres but don't want to give up SQL.
- You need **multi-region** writes/reads with strong consistency.
- You want to consolidate operational DBs (transactional + key-value + time-series).
- You're building a system where downtime is unacceptable (financial, telecom, SaaS).

## When it's *not* the right tool

- Your workload fits on a single Postgres node and probably always will — distributed SQL adds latency you don't need.
- You need <1ms point lookups at extreme scale — a purpose-built KV store (DynamoDB, Redis) may be cheaper.
- Heavy analytical/OLAP workloads — pair Yugabyte with a columnar warehouse instead.

## A bit of history

- 2016 — Founded by ex-Facebook engineers who built Cassandra and HBase at scale.
- 2019 — Core source released under Apache 2.0.
- Today — Used by financial services, telecom, retail, and SaaS companies needing distributed SQL.

Next: [Architecture overview →](02-architecture.md)
