# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-paced learning project for **YugabyteDB** (distributed SQL, Postgres wire-compatible). It is not a deliverable product — it is reading material + runnable exercises + one small reference app. Three top-level areas:

- `docs/` — markdown reading material (Phase 1–4 of the roadmap in [README.md](README.md)).
- `exercises/` — `.sql` / `.cql` files meant to be executed against a live cluster, in order. `ysql/` is the Postgres-compatible track; `ycql/` is the Cassandra-compatible track.
- `sample-app/` — a small Node.js + Fastify order-management service backed by YSQL.

Most "code" in this repo is SQL or markdown. Treat exercise comments as load-bearing — they call out where YugabyteDB diverges from vanilla Postgres/Cassandra.

## Running the database

Everything assumes a YugabyteDB cluster is reachable on `localhost:5433` (YSQL) and `localhost:9042` (YCQL). Two compose files in `setup/`:

```bash
# Single-node, RF=1 — default for exercises and sample-app
cd setup && docker compose up -d

# 3-node, RF=3 — for leader election / failover experiments
cd setup && docker compose -f docker-compose.3node.yml up -d
```

Shells:

```bash
docker exec -it yugabyte ysqlsh -h yugabyte    # YSQL (Postgres-compatible)
docker exec -it yugabyte ycqlsh yugabyte       # YCQL (Cassandra-compatible)
```

UIs: Master http://localhost:7000 · TServer http://localhost:9000 · yugabyted http://localhost:15433.

`docker compose down -v` wipes the volume — fine for this repo, since everything is reproducible from `migrate.js` + `seed.js` or the exercise scripts.

## Running exercises

```bash
docker exec -i yugabyte ysqlsh -h yugabyte < exercises/ysql/01_basics.sql
docker exec -i yugabyte ycqlsh yugabyte      < exercises/ycql/01_basics.cql
```

The files are ordered (`01_…` → `05_…`) and build on each other.

## Sample app (`sample-app/`)

Node 20+, ESM, Fastify 4, `pg` driver. Run from `sample-app/`:

```bash
cp .env.example .env       # PG* vars default to the docker compose cluster
docker exec -it yugabyte ysqlsh -h yugabyte -c "CREATE DATABASE orders_app;"
npm install                # or pnpm install — lockfile is pnpm
npm run migrate            # apply schema (src/migrate.js)
npm run seed               # insert demo customers + products
npm start                  # serves on :3000
npm run dev                # same, with --watch
```

No test suite, no linter, no build step.

### Architecture notes worth knowing before editing

The sample app is small but the patterns are deliberate — most edits should preserve them:

- **`src/db.js`** exports a single `pg.Pool` and a `withRetry(fn, attempts=5)` helper. Any code path that runs a `SERIALIZABLE` transaction must go through `withRetry` so `SQLSTATE 40001` (serialization failure) is retried with exponential backoff. This is mandatory under distributed-SQL, not optional. The comment in `db.js` also notes that production code should switch from `pg` to `@yugabytedb/pg` (the smart driver) for tserver-aware load balancing.
- **Schema (`src/migrate.js`)** uses Yugabyte-specific shapes that aren't valid in vanilla Postgres:
  - `orders` PK is `PRIMARY KEY ((customer_id) HASH, id)` — hash-shards on `customer_id` so one customer's orders co-locate on one tablet. Don't "fix" this to a plain `PRIMARY KEY (id)` unless you understand the trade-off.
  - `idx_orders_status` is a covering index using `INCLUDE (...)` to avoid a second tablet RPC. Several exercises reference this index by name.
- **`POST /orders` in `src/server.js`** is the canonical multi-table distributed-transaction example: `BEGIN ISOLATION LEVEL SERIALIZABLE` → `SELECT ... FOR UPDATE` on `products` → update stock → insert `order_items` → update `orders.total` → `COMMIT`, all wrapped in `withRetry`. Touch with care.

## Conventions

- Markdown link style is `[text](path)` with relative paths from the file's location — used by both `docs/` cross-links and the README roadmap.
- Exercise files mix runnable SQL with `--` comments that explain *why* — keep that style when adding to them.
- `notes/cheatsheet.md` is the quick-reference for Yugabyte-specific SQL (e.g. `yb_servers()`, `yb_table_properties()`, `yb_hash_code()`, follower-read GUCs); check it before reinventing a query.
