# Resources

Curated list of the best places to dig deeper after working through this project.

## Official

- [YugabyteDB docs](https://docs.yugabyte.com/) — the canonical reference. Always start here.
- [YugabyteDB GitHub](https://github.com/yugabyte/yugabyte-db) — source code, issues, design docs.
- [University courses (free)](https://university.yugabyte.com/) — structured video courses covering YSQL, YCQL, and operations.
- [Architecture deep dive](https://docs.yugabyte.com/preview/architecture/) — the formal design docs for DocDB, Raft, transactions.

## Deep-dive reading

- **"Distributed PostgreSQL on a Google Spanner Architecture"** — the foundational design blog series. Search the Yugabyte blog for the storage layer and the query layer posts.
- **DocDB internals** — start at `docs.yugabyte.com` → Architecture → DocDB.
- **Hybrid Logical Clocks** — the original paper by Kulkarni et al. explains why HLCs work without TrueTime.
- **Raft consensus** — Diego Ongaro's thesis is still the clearest explanation; everything Yugabyte does on the storage layer assumes you understand Raft.

## Comparisons

- [Yugabyte vs CockroachDB](https://www.yugabyte.com/yugabytedb-vs-cockroachdb/) — the natural competitor. Both are distributed SQL with Raft; the differences are in the query layer (Postgres-fork vs reimplementation) and pricing.
- [Yugabyte vs Spanner](https://docs.yugabyte.com/preview/faq/comparisons/google-spanner/) — Spanner needs TrueTime hardware; Yugabyte uses HLC instead.
- [Yugabyte vs Aurora](https://docs.yugabyte.com/preview/faq/comparisons/amazon-aurora/) — Aurora is HA but not horizontally scalable; Yugabyte is both.

## Driver reference

- **Python** — `psycopg2`/`psycopg3` work; for prod use `yugabytedb-psycopg2` (smart driver).
- **Node.js** — `pg` works; for prod use [`@yugabytedb/pg`](https://github.com/yugabyte/node-postgres) for cluster-aware load balancing.
- **Java** — `yugabytedb-jdbc-driver` is a drop-in JDBC replacement with topology awareness.
- **Go** — `yb-pgx` is the smart driver fork of `jackc/pgx`.

## Community

- [Yugabyte community Slack](https://communityinviter.com/apps/yugabyte-db/register) — fast answers from engineers.
- [Yugabyte forum](https://forum.yugabyte.com/) — searchable, good for design questions.
- [GitHub discussions](https://github.com/yugabyte/yugabyte-db/discussions) — issues and design conversations.

## Talks worth watching

- "Distributed SQL Summit" recordings on YouTube — annual user conference.
- "PostgreSQL & YugabyteDB" talks from PGConf for the practical migration angle.

## Operations / production reading

- [Yugabyte cloud architectures](https://docs.yugabyte.com/preview/explore/multi-region-deployments/) — single-region HA, multi-region sync, xCluster async.
- [Backup & restore](https://docs.yugabyte.com/preview/manage/backup-restore/) — `yb-admin` snapshots, distributed backups to S3/GCS.
- [Monitoring](https://docs.yugabyte.com/preview/explore/observability/) — Prometheus metrics, Grafana dashboards (official ones exist).
