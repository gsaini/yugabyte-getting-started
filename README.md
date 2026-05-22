# YugabyteDB — Getting Started

![YugabyteDB](https://img.shields.io/badge/YugabyteDB-2024-FF6600?style=for-the-badge&logo=yugabytedb&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Compatible-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-24-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Fastify](https://img.shields.io/badge/Fastify-4.x-000000?style=for-the-badge&logo=fastify&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

A self-paced learning project to understand **YugabyteDB** end-to-end: what it is, how it works internally, and how to build against it.

YugabyteDB is a **distributed SQL** database that combines PostgreSQL-compatible APIs with the horizontal scalability and resilience of NoSQL systems like Cassandra and Google Spanner.

## Learning Roadmap

Work through these in order. Each phase has reading material in [docs/](docs/) and hands-on exercises in [exercises/](exercises/).

### Phase 1 — Foundations

- [What is YugabyteDB?](docs/01-introduction.md) — distributed SQL, history, when to use it
- [Architecture overview](docs/02-architecture.md) — YB-TServer, YB-Master, DocDB, Raft

### Phase 2 — APIs

- [YSQL vs YCQL](docs/03-ysql-vs-ycql.md) — the two query layers and when to choose each
- Exercises: [YSQL basics](exercises/ysql/) and [YCQL basics](exercises/ycql/)

### Phase 3 — Internals

- [Sharding and replication](docs/04-sharding-replication.md) — tablets, leader/follower, Raft groups
- [Distributed transactions](docs/05-transactions.md) — hybrid logical clocks, isolation levels

### Phase 4 — Operations

- [Performance & tuning](docs/06-performance.md) — tablet splitting, colocation, indexes
- [Setup guide](setup/README.md) — Docker, native install, multi-node clusters

### Phase 5 — Application

- [Sample app](sample-app/) — a Node.js + Fastify service that uses YSQL for an order-management workflow

## Quick start

```bash
# Spin up a single-node YugabyteDB locally with Docker
cd setup && docker compose up -d

# Connect via ysqlsh (PostgreSQL-compatible shell)
docker exec -it yugabyte ysqlsh -h yugabyte
```

Then jump into [exercises/ysql/01_basics.sql](exercises/ysql/01_basics.sql).

## Reference

- [Cheatsheet](notes/cheatsheet.md) — common commands and SQL patterns
- [Resources](notes/resources.md) — official docs, talks, deep-dive blog posts
