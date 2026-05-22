# Sample app — Order management on YugabyteDB

A tiny Node.js + Fastify service that uses YugabyteDB (YSQL) as its database.

It demonstrates the patterns you'll most often use against Yugabyte:

- Connecting from a Postgres driver (`pg`) — Yugabyte is wire-compatible.
- A hash-sharded primary key (`(customer_id) HASH, id`) so a customer's orders co-locate.
- A covering index (`INCLUDE`) to avoid a second tablet RPC.
- A multi-table distributed transaction at **Serializable** isolation with `SELECT ... FOR UPDATE`.
- A retry loop on `SQLSTATE 40001` (serialization failure) — mandatory for any distributed-SQL app.

## Run it

```bash
# 1. Make sure YugabyteDB is running (see ../setup/README.md)
cd ../setup && docker compose up -d && cd ../sample-app

# 2. Create the target database
docker exec -it yugabyte ysqlsh -h yugabyte -c "CREATE DATABASE orders_app;"

# 3. Install deps and run
cp .env.example .env
npm install
npm run migrate
npm run seed
npm start
```

## Try it

```bash
# Health
curl localhost:3000/health

# List things
curl localhost:3000/customers | jq
curl localhost:3000/products | jq

# Place an order — pick a customer_id and a product_id from the lists above
curl -X POST localhost:3000/orders \
  -H 'content-type: application/json' \
  -d '{
        "customer_id": "<uuid>",
        "items": [
          { "product_id": "<uuid>", "qty": 2 }
        ]
      }'

# See that customer's orders
curl localhost:3000/orders/<customer_uuid> | jq
```

## What to look at after running this

- Open the master UI at http://localhost:7000 — find the `orders` table and check how many tablets it has.
- Run `EXPLAIN (ANALYZE, DIST) SELECT * FROM orders WHERE customer_id = '<uuid>'` and confirm it hits exactly one tablet (because of the hash PK).
- Drop the covering index and re-run a `GET /orders/by-status` style query — watch the RPC count change.
