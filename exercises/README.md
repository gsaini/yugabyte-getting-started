# Exercises

Hands-on practice. Work through each file in order, and **read the comments** — many of them flag where YugabyteDB behaves differently from vanilla Postgres or Cassandra.

## YSQL track
1. [01_basics.sql](ysql/01_basics.sql) — connect, create tables, basic CRUD
2. [02_sharding.sql](ysql/02_sharding.sql) — HASH vs RANGE primary keys, pre-splitting
3. [03_indexes.sql](ysql/03_indexes.sql) — secondary indexes, covering indexes, INCLUDE
4. [04_transactions.sql](ysql/04_transactions.sql) — isolation levels, retries, FOR UPDATE
5. [05_observe.sql](ysql/05_observe.sql) — yb_servers(), EXPLAIN DIST, pg_stat_statements

## YCQL track
1. [01_basics.cql](ycql/01_basics.cql) — keyspaces, tables, CRUD
2. [02_transactions.cql](ycql/02_transactions.cql) — YCQL's distributed transactions

## How to run

YSQL:
```bash
docker exec -i yugabyte ysqlsh -h yugabyte < exercises/ysql/01_basics.sql
```

YCQL:
```bash
docker exec -i yugabyte ycqlsh yugabyte < exercises/ycql/01_basics.cql
```

Or open `ysqlsh` / `ycqlsh` interactively and paste sections.
