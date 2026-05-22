-- ============================================================
-- Exercise 1 — YCQL basics
-- ============================================================
-- YCQL = Cassandra Query Language, with strong consistency
-- and ACID transactions on top.
-- Run with:  docker exec -it yugabyte ycqlsh yugabyte
-- ============================================================

-- ---- Create a keyspace (CQL's "database") ----
CREATE KEYSPACE IF NOT EXISTS iot;

USE iot;

-- ---- A time-series table for sensor data ----
-- Partition key:  sensor_id  (hash-distributed across tablets)
-- Clustering key: ts DESC    (sorted within a partition)
CREATE TABLE sensor_readings (
  sensor_id  UUID,
  ts         TIMESTAMP,
  temp       DOUBLE,
  humidity   DOUBLE,
  PRIMARY KEY ((sensor_id), ts)
) WITH CLUSTERING ORDER BY (ts DESC)
  AND default_time_to_live = 2592000;  -- 30 days TTL

-- ---- Insert some data ----
INSERT INTO sensor_readings (sensor_id, ts, temp, humidity)
  VALUES (uuid(), totimestamp(now()), 22.5, 48.0);

INSERT INTO sensor_readings (sensor_id, ts, temp, humidity)
  VALUES (uuid(), totimestamp(now()), 23.1, 47.5);

-- ---- Query the latest reading for a sensor ----
-- Always filter by partition key for fast queries
SELECT * FROM sensor_readings
WHERE sensor_id = <paste-uuid-here>
LIMIT 1;

-- ---- Secondary index (strongly consistent in YCQL, unlike Cassandra!) ----
CREATE INDEX ON sensor_readings (temp);

-- ---- A JSONB column ----
CREATE TABLE devices (
  device_id  UUID PRIMARY KEY,
  metadata   JSONB
);

INSERT INTO devices (device_id, metadata)
  VALUES (uuid(), '{"firmware": "1.2.3", "location": "warehouse-A"}');

SELECT * FROM devices;

-- ---- Schema inspection ----
DESCRIBE TABLES;
DESCRIBE sensor_readings;
