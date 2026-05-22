# 5. Distributed Transactions

Yugabyte supports **full ACID transactions across multiple tablets and nodes** — the hardest problem in distributed databases. This page covers how it works and how to use it correctly.

## Isolation levels

YSQL supports three isolation levels (Postgres has four, but `Read Uncommitted` is treated as `Read Committed`):

| Level                | What it guarantees                                    | When to use |
|----------------------|-------------------------------------------------------|-------------|
| Read Committed       | Each statement sees a fresh snapshot                  | Default for most apps |
| Repeatable Read      | Whole transaction sees one snapshot (snapshot iso)    | Multi-statement reads |
| Serializable         | As if transactions ran one-at-a-time                  | Strict invariants, money |

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

> Default in Yugabyte YSQL is **Read Committed** (matching Postgres), but you can change it.

## How a distributed txn works (HLC + 2PC)

Internally, Yugabyte uses:

1. **Hybrid Logical Clocks (HLC)** — each node's clock is a tuple `(physical_time, logical_counter)`. This gives a total order on events without requiring a globally-synced atomic clock (which Spanner has via TrueTime).
2. **Provisional records** — uncommitted writes are stored in a separate area, tagged with the txn ID.
3. **Two-phase commit** — when you `COMMIT`:
   - Phase 1: status tablet records "committed at HLC=X".
   - Phase 2: provisional records get cleaned up / promoted to permanent records lazily.

The clever bit: once the **status record** flips to committed, the txn is durable — even before all provisional records have been promoted. That's how Yugabyte hits low commit latencies.

## Conflict handling

When two txns touch the same row, one of two things happens:

- **Optimistic** (default in Serializable): both run; the second to commit detects the conflict and is **aborted with a serialization error**. Your app must retry.
- **Pessimistic locking** (`SELECT ... FOR UPDATE`): the first txn acquires a lock; the second waits.

```sql
-- Pessimistic: the row is locked until commit/rollback
BEGIN;
  SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

> Always handle the **`40001` serialization failure** error in app code with a retry loop. This is normal in any distributed DB at Serializable isolation.

## Read latency: leader vs follower

By default, reads inside a txn go to the **tablet leader** — strongly consistent but cross-DC latency if the leader is far.

You can opt into **follower reads** for read-only workloads that tolerate slight staleness:

```sql
SET yb_read_from_followers = true;
SET default_transaction_read_only = true;
SET yb_follower_read_staleness_ms = 30000;  -- up to 30s stale
```

This is huge for global read replicas — a user in Tokyo reads from a follower in Tokyo instead of waiting for the leader in Virginia.

## Common gotchas

- **High contention rows** (a counter incremented by everyone) → use serializable + retry, or rethink the schema (sharded counter).
- **Long-running txns** → hold provisional records → slow other txns. Keep txns short.
- **Cross-tablet writes** are slower than single-tablet writes — design your PK so common writes hit one tablet.
- **`SELECT FOR UPDATE` on indexes** — locks the index entry, not just the row. Watch this if you have many indexes.

## Practical pattern: idempotent retry

```python
from psycopg2 import errors
import time

def with_retry(conn, fn, max_attempts=5):
    for attempt in range(max_attempts):
        try:
            with conn:
                return fn(conn)
        except errors.SerializationFailure:
            time.sleep(0.05 * (2 ** attempt))  # exponential backoff
    raise RuntimeError("too many serialization failures")
```

Next: [Performance & tuning →](06-performance.md)
