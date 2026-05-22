# Setup

Three ways to run YugabyteDB locally, from easiest to most realistic.

## Option 1 — Single-node Docker (recommended for learning)

The fastest way to get going. Single node, RF=1 — fine for exercises.

```bash
cd setup
docker compose up -d
```

Wait ~15 seconds for it to be ready, then:

```bash
# Postgres-compatible shell
docker exec -it yugabyte ysqlsh -h yugabyte

# Cassandra-compatible shell
docker exec -it yugabyte ycqlsh yugabyte
```

UIs:
- Master:   http://localhost:7000
- TServer:  http://localhost:9000

Stop & wipe:
```bash
docker compose down -v
```

## Option 2 — 3-node Docker cluster (more realistic)

Run three TServers + masters so you can see leader election, tablet distribution, and failover. See [`docker-compose.3node.yml`](docker-compose.3node.yml).

```bash
docker compose -f docker-compose.3node.yml up -d
```

Try killing one node and watch the cluster heal:

```bash
docker stop yb-tserver-2
# wait a few seconds
docker exec -it yb-tserver-1 ysqlsh -h yb-tserver-1 -c "SELECT * FROM yb_servers();"
```

## Option 3 — Native install (yugabyted)

Closest to a real deployment.

```bash
# macOS
brew install yugabyte

# Start a local single-node cluster
yugabyted start

# Stop
yugabyted stop

# Reset everything
yugabyted destroy
```

For multi-node on one machine:
```bash
yugabyted start --advertise_address=127.0.0.1 --base_dir=/tmp/yb1
yugabyted start --advertise_address=127.0.0.2 --base_dir=/tmp/yb2 --join=127.0.0.1
yugabyted start --advertise_address=127.0.0.3 --base_dir=/tmp/yb3 --join=127.0.0.1
```

## Connecting from your laptop

Both APIs are exposed on localhost:

| API   | Port  | Default user | Default password |
|-------|-------|--------------|------------------|
| YSQL  | 5433  | `yugabyte`   | (none in dev)    |
| YCQL  | 9042  | `cassandra`  | `cassandra`      |

Python (psycopg2):
```python
import psycopg2
conn = psycopg2.connect(
    host="localhost", port=5433, dbname="yugabyte", user="yugabyte"
)
```

`psql` works too — just point at port 5433:
```bash
psql -h localhost -p 5433 -U yugabyte
```

## Troubleshooting

- **"connection refused" on 5433** — container not ready yet, or it crashed. Check `docker logs yugabyte`.
- **macOS slow disk I/O** — Docker Desktop's filesystem is the bottleneck. For real benchmarking use `yugabyted` natively or a Linux VM.
- **Out of memory** — bump Docker Desktop's memory to ≥4GB.
