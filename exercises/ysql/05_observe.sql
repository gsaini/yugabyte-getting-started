-- ============================================================
-- Exercise 5 — Observability & introspection
-- ============================================================
-- The same `pg_*` views Postgres has, plus Yugabyte-specific
-- `yb_*` functions for cluster state.
-- ============================================================

\c learn_yb

-- ---- Cluster topology ----
SELECT * FROM yb_servers();

-- Which user are you, what node, what session?
SELECT current_user, inet_server_addr(), inet_server_port(), pg_backend_pid();

-- ---- Table properties (tablets, replication) ----
SELECT * FROM yb_table_properties('orders'::regclass);

-- ---- EXPLAIN with distributed RPC counts ----
EXPLAIN (ANALYZE, DIST, VERBOSE)
SELECT * FROM orders WHERE customer_id = (SELECT id FROM customers LIMIT 1);

-- ---- Slow query analysis ----
-- pg_stat_statements is enabled by default in Yugabyte
SELECT
  substring(query, 1, 80) AS query,
  calls,
  round(mean_exec_time::numeric, 2) AS avg_ms,
  rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Reset the stats:
SELECT pg_stat_statements_reset();

-- ---- Active sessions / lock waits ----
SELECT pid, state, query_start, substring(query, 1, 60) AS query
FROM pg_stat_activity
WHERE state != 'idle';

-- ---- The admin UI ----
-- Open http://localhost:7000 in your browser for a visual view of
-- masters, tservers, tablets, leader balancing, and replication state.
