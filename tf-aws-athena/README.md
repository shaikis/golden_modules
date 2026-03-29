# tf-aws-athena

Production-grade Terraform module for **Amazon Athena** — workgroups, Glue catalog databases, named queries, federated data catalogs, prepared statements, capacity reservations, and IAM wiring.

---

## Architecture

```
                         ┌─────────────────────────────────────────────────────────┐
                         │                    AWS Account                          │
                         │                                                         │
  ┌──────────────┐       │  ┌──────────────────────────────────────────────────┐   │
  │  S3 Data Lake│       │  │              AWS Glue Data Catalog               │   │
  │              │       │  │                                                  │   │
  │  raw_zone/   │──────▶│  │  raw_zone DB   processed_zone DB   analytics DB │   │
  │  processed/  │       │  │      │               │                  │        │   │
  │  analytics/  │       │  └──────┼───────────────┼──────────────────┼────────┘   │
  └──────────────┘       │         └───────────────┼──────────────────┘            │
         ▲               │                         ▼                               │
         │               │  ┌──────────────────────────────────────────────────┐   │
         │               │  │                Amazon Athena                     │   │
         │               │  │                                                  │   │
         │               │  │  ┌────────────┐  ┌────────────┐  ┌───────────┐  │   │
         │               │  │  │  primary   │  │data_science│  │etl_       │  │   │
         │               │  │  │ workgroup  │  │ workgroup  │  │pipelines  │  │   │
         │               │  │  │ (10 GB cap)│  │(no cap)    │  │(100 GB)   │  │   │
         │               │  │  └────────────┘  └────────────┘  └───────────┘  │   │
         │               │  │  ┌────────────┐                                  │   │
         │               │  │  │ reporting  │  Named Queries  Prepared Stmts   │   │
         │               │  │  │ workgroup  │  Data Catalogs  Capacity Rsv     │   │
         │               │  │  │ (5 GB cap) │                                  │   │
         │               │  └──────────────────────────────────────────────────┘   │
         │               │                         │                               │
         └───────────────│─────────────────────────┘                               │
                         │                         │                               │
                         │                         ▼                               │
                         │  ┌───────────────────────────────────────────────────┐  │
                         │  │              Query Results (S3)                   │  │
                         │  │      s3://prod-athena-results/primary/            │  │
                         │  │      s3://prod-athena-results/data-science/       │  │
                         │  │      s3://prod-athena-results/etl-pipelines/      │  │
                         │  │      s3://prod-athena-results/reporting/          │  │
                         │  └──────────────────────────────┬────────────────────┘  │
                         └─────────────────────────────────┼─────────────────────  │
                                                           │
                    ┌──────────────────────────────────────┼──────────────────┐
                    │               Consumers              │                  │
                    │                                      ▼                  │
                    │  ┌───────────────┐  ┌─────────────────────┐            │
                    │  │  Amazon       │  │   Jupyter /         │            │
                    │  │  QuickSight   │  │   SageMaker Studio  │            │
                    │  └───────────────┘  └─────────────────────┘            │
                    │  ┌───────────────┐  ┌─────────────────────┐            │
                    │  │  Tableau /    │  │  AWS SDK / boto3    │            │
                    │  │  Looker       │  │  (application code) │            │
                    │  └───────────────┘  └─────────────────────┘            │
                    └────────────────────────────────────────────────────────┘
```

---

## Features

| Resource | Description |
|---|---|
| `aws_athena_workgroup` | Per-team workgroups with scan limits, engine version, KMS encryption |
| `aws_athena_database` | Glue catalog databases backed by S3 with encryption |
| `aws_athena_named_query` | Saved SQL queries + pre-built template library |
| `aws_athena_data_catalog` | Federated catalogs: LAMBDA, GLUE, HIVE |
| `aws_athena_prepared_statement` | Parameterized queries with `?` placeholders |
| `aws_athena_capacity_reservation` | Provisioned DPUs for predictable performance |
| IAM roles | Analyst (least-privilege) and admin roles with S3 + KMS + Glue policies |

---

## Workgroup Isolation Strategy

Athena workgroups are the primary mechanism for **multi-team cost control and governance**:

```
Team               Workgroup       Scan Limit   Encryption   Notes
─────────────────  ──────────────  ───────────  ───────────  ──────────────────────────
Data Analysts      primary         10 GB        SSE-KMS      Shared analyst workgroup
ML / Data Science  data_science    None         SSE-KMS      Exploratory — no throttle
ETL Pipelines      etl_pipelines   100 GB       SSE-KMS      CTAS + bulk transforms
BI / Reporting     reporting       5 GB         SSE-S3       QuickSight integration
```

**Best practices:**
- Set `enforce_workgroup_configuration = true` on shared workgroups so users cannot override the scan limit or output location.
- Keep `enforce_workgroup_configuration = false` only for data scientists who need flexibility.
- Separate result prefixes per workgroup simplify S3 lifecycle policies.

---

## Query Cost Estimation

Athena charges **$5 per TB scanned** (us-east-1). Use `bytes_scanned_cutoff_per_query` to cap runaway queries:

```hcl
bytes_scanned_cutoff_per_query = 5368709120   # 5 GB  → max $0.025 per query
bytes_scanned_cutoff_per_query = 10737418240  # 10 GB → max $0.050 per query
bytes_scanned_cutoff_per_query = 107374182400 # 100 GB → max $0.50 per query
```

Athena cancels the query when the threshold is reached. The CloudWatch metric `DataScannedInBytes` per workgroup gives a monthly cost rollup.

---

## Partition Pruning Best Practices

Partitioned tables dramatically reduce data scanned — critical for cost and latency:

1. **Partition on high-cardinality time columns** (`year/month/day` or `dt=YYYY-MM-DD`).
2. **Always filter on partition columns** in WHERE clauses:
   ```sql
   -- Good: partition pruning in effect
   SELECT * FROM orders WHERE dt = '2024-01-15';

   -- Bad: full table scan
   SELECT * FROM orders WHERE DATE(order_ts) = DATE '2024-01-15';
   ```
3. **Register new partitions** with `MSCK REPAIR TABLE` (Hive-style) or `ALTER TABLE ADD PARTITION` (preferred for large tables).
4. **Use projection partitions** for time-series data to avoid Glue catalog overhead:
   ```sql
   -- Enable partition projection in table properties
   'projection.enabled' = 'true',
   'projection.dt.type' = 'date',
   'projection.dt.range' = '2022-01-01,NOW',
   'projection.dt.format' = 'yyyy-MM-dd'
   ```

---

## Iceberg Table Management

### OPTIMIZE (file compaction)

Small files from streaming ingestion or frequent writes degrade query performance. Run periodically:

```sql
-- Rewrite small files using BIN_PACK strategy
OPTIMIZE processed_zone.orders REWRITE DATA USING BIN_PACK;

-- With file size target (256 MB recommended)
OPTIMIZE processed_zone.orders REWRITE DATA USING BIN_PACK
  WHERE dt >= '2024-01-01';
```

### VACUUM (snapshot expiry)

Iceberg retains old snapshots for time-travel. Clean up to reclaim S3 storage:

```sql
-- Remove snapshots older than retention period (default: 5 days)
VACUUM processed_zone.orders;

-- Explicit retention period
VACUUM processed_zone.orders RETAIN 7 DAYS EXPIRE SNAPSHOTS;
```

**Recommended schedule:** OPTIMIZE daily, VACUUM weekly via EventBridge + Step Functions.

---

## CTAS (CREATE TABLE AS SELECT) Patterns

CTAS writes Athena query output directly to S3 as a new table — ideal for ETL:

```sql
-- Convert CSV raw data to Parquet with partitioning
CREATE TABLE processed_zone.orders_parquet
WITH (
  format            = 'PARQUET',
  parquet_compression = 'SNAPPY',
  partitioned_by    = ARRAY['dt'],
  location          = 's3://prod-data-lake/processed/orders/'
) AS
SELECT
  order_id,
  customer_id,
  order_amount,
  status,
  DATE_FORMAT(order_ts, '%Y-%m-%d') AS dt
FROM raw_zone.orders_csv
WHERE order_ts >= DATE '2024-01-01';

-- CTAS to create Iceberg table
CREATE TABLE processed_zone.orders_iceberg
WITH (
  table_type = 'ICEBERG',
  format     = 'PARQUET',
  location   = 's3://prod-data-lake/iceberg/orders/'
) AS
SELECT * FROM processed_zone.orders_parquet;
```

---

## Federated Queries (Lambda Connector)

Athena federated query connects to external data sources (RDS, DynamoDB, Redis, on-prem):

```hcl
data_catalogs = {
  federated_rds = {
    type        = "LAMBDA"
    description = "Aurora PostgreSQL connector via Lambda"
    parameters = {
      function = "arn:aws:lambda:us-east-1:123456789012:function:athena-rds-connector"
    }
  }
}
```

Query across sources in a single SQL:

```sql
-- Join S3 data lake with live RDS data
SELECT
  dl.order_id,
  dl.order_amount,
  rds.customer_email,
  rds.tier
FROM processed_zone.orders dl
JOIN "lambda:federated_rds".public.customers rds
  ON dl.customer_id = rds.customer_id
WHERE dl.dt = '2024-01-15';
```

---

## Result Reuse (Query Result Caching)

Athena automatically reuses query results when:
- The same query is re-executed within the result reuse window (max 60 minutes).
- The underlying data has not changed.

Enable via the workgroup `result_configuration` or per-execution via the SDK:

```python
import boto3
client = boto3.client('athena')
client.start_query_execution(
    QueryString="SELECT * FROM orders LIMIT 10",
    WorkGroup="reporting",
    ResultReuseConfiguration={
        "ResultReuseByAgeConfiguration": {
            "Enabled": True,
            "MaxAgeInMinutes": 60
        }
    }
)
```

---

## Cost Optimization

| Technique | Savings |
|---|---|
| Convert to **Parquet or ORC** | 80-90% less data scanned vs CSV/JSON |
| **Partition** by date/region | Eliminates full-table scans |
| **Columnar projection** — select only needed columns | Proportional to column count |
| **Compress** with SNAPPY or ZSTD | 30-70% smaller files |
| Use **scan limits** per workgroup | Hard cap on per-query cost |
| **Result caching** for repeated queries | $0 for cache hits |
| **Partition projection** for time-series | Eliminates Glue API calls |
| Run **OPTIMIZE** to compact small files | Reduces file-open overhead |

Quick math: 1 TB of raw JSON → ~100 GB Snappy Parquet with partitioning = **10x cost reduction**.

---

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

### Minimal

```hcl
module "athena" {
  source = "github.com/your-org/tf-aws-athena"

  name_prefix = "prod"

  workgroups = {
    primary = {
      result_configuration = {
        output_location = "s3://my-results-bucket/primary/"
        encryption_type = "SSE_S3"
      }
    }
  }

  databases = {
    analytics = {
      bucket = "my-data-lake-bucket"
    }
  }
}
```

### With KMS and scan limit

```hcl
module "athena" {
  source = "github.com/your-org/tf-aws-athena"

  name_prefix         = "prod"
  results_kms_key_arn = aws_kms_key.athena.arn
  results_bucket_arns = [aws_s3_bucket.results.arn]

  workgroups = {
    primary = {
      bytes_scanned_cutoff_per_query = 10737418240  # 10 GB
      engine_version                 = "Athena engine version 3"

      result_configuration = {
        output_location = "s3://${aws_s3_bucket.results.id}/primary/"
        encryption_type = "SSE_KMS"
        kms_key_arn     = aws_kms_key.athena.arn
      }
    }
  }
}
```

---

## 15 Real-World SRE / Data Engineering Scenarios

### 1. Ad-hoc exploration — preview table data safely (scan limit)

A data analyst needs to quickly inspect a new dataset without risking a costly full-table scan.

**Solution:** Use the `primary` workgroup with a 10 GB scan limit and the `preview_orders` named query.

```sql
-- Named query: preview-orders (saved in Athena console)
SELECT * FROM processed_zone.orders LIMIT 10;
```

The workgroup's `bytes_scanned_cutoff_per_query = 10737418240` kills the query if it attempts to scan more than 10 GB, preventing runaway costs.

---

### 2. Partition repair after new S3 data lands

A Glue job writes new daily partitions to S3 but the Athena table still returns stale results.

**Solution:** Run the `repair_partitions` named query after each Glue job via Step Functions or Lambda.

```sql
-- Named query: repair-orders-partitions
MSCK REPAIR TABLE raw_zone.orders;
```

For large tables prefer `ALTER TABLE ADD PARTITION` to avoid scanning all S3 prefixes.

---

### 3. Daily revenue aggregation report

Finance needs a daily revenue report generated every morning before 8 AM.

**Solution:** Schedule via EventBridge + Lambda using the `daily_revenue` named query in the `reporting` workgroup.

```sql
SELECT
  DATE(order_ts)           AS order_date,
  SUM(order_amount)        AS total_revenue,
  COUNT(DISTINCT order_id) AS total_orders
FROM processed_zone.orders
WHERE order_ts >= DATE_ADD('day', -30, CURRENT_DATE)
  AND status = 'COMPLETED'
GROUP BY DATE(order_ts)
ORDER BY order_date DESC;
```

---

### 4. Cross-account S3 data access via federated catalog

A partner team stores data in a separate AWS account. Direct S3 access requires cross-account bucket policies.

**Solution:** Deploy the `federated_lambda` data catalog pointing to a Lambda connector that assumes a cross-account role. Query using the catalog prefix:

```sql
SELECT * FROM "lambda:federated_lambda".partner_db.transactions
WHERE event_date = '2024-01-15';
```

---

### 5. Data quality validation — NULL checks, duplicate detection

Data pipeline reliability: detect upstream data quality issues before they reach dashboards.

```sql
-- NULL check (saved as named query: data-quality-null-check)
SELECT
  COUNT(*)                                                      AS total_rows,
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)            AS null_order_ids,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)         AS null_customer_ids
FROM processed_zone.orders;

-- Duplicate detection
SELECT order_id, COUNT(*) AS cnt
FROM processed_zone.orders
GROUP BY order_id
HAVING COUNT(*) > 1;
```

---

### 6. Cost monitoring — scan bytes per workgroup

SRE needs to track Athena costs per team to allocate chargebacks.

```sql
-- Query the CloudWatch Athena metrics via Athena (or use cost-by-workgroup named query)
SELECT
  workgroup,
  SUM(data_scanned_in_bytes) / POWER(1024, 4)    AS tb_scanned,
  SUM(data_scanned_in_bytes) / POWER(1024, 4) * 5 AS cost_usd
FROM information_schema.__internal_partitions__
WHERE submit_date >= DATE_ADD('day', -30, CURRENT_DATE)
GROUP BY workgroup
ORDER BY tb_scanned DESC;
```

Alert when a workgroup exceeds budget using CloudWatch Alarms on `DataScannedInBytes`.

---

### 7. Iceberg table compaction (OPTIMIZE)

After 7 days of streaming writes, the Iceberg orders table has 50,000 small files (~1 MB each). Query latency has increased from 3 s to 45 s.

**Solution:** Run the `optimize_orders` named query in the `etl_pipelines` workgroup:

```sql
OPTIMIZE processed_zone.orders REWRITE DATA USING BIN_PACK;
```

Schedule weekly via EventBridge. After compaction: file count drops from 50,000 to ~400, query latency returns to 3 s.

---

### 8. Iceberg snapshot cleanup (VACUUM)

S3 storage costs are increasing because old Iceberg snapshots are accumulating.

**Solution:** Run `vacuum_orders` in the `etl_pipelines` workgroup:

```sql
VACUUM processed_zone.orders RETAIN 7 DAYS EXPIRE SNAPSHOTS;
```

This removes snapshots older than 7 days while preserving the time-travel window. Expected storage reduction: 40-60% for high-write tables.

---

### 9. CDC data analysis — find latest records by event_time

A CDC pipeline writes multiple versions of each record. Find the latest state of each order.

```sql
-- Deduplicate CDC records using ROW_NUMBER
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY event_time DESC
    ) AS rn
  FROM raw_zone.orders_cdc
  WHERE dt >= '2024-01-01'
)
SELECT * FROM ranked WHERE rn = 1 AND op != 'D';
```

---

### 10. Security audit — query CloudTrail logs in S3

Security team needs to find all IAM role assumptions in the past 24 hours.

```sql
-- Query CloudTrail logs stored in S3 (requires CloudTrail table in Athena)
SELECT
  eventtime,
  useridentity.arn     AS assumed_by,
  requestparameters    AS role_details,
  sourceipaddress
FROM raw_zone.cloudtrail_logs
WHERE dt = '2024-01-15'
  AND eventname = 'AssumeRole'
  AND errorcode IS NULL
ORDER BY eventtime DESC;
```

---

### 11. Application logs analysis — query ALB access logs

Diagnose a spike in 5xx errors from the ALB without downloading log files.

```sql
-- ALB access log analysis (requires ALB log table in Athena)
SELECT
  target_status_code,
  COUNT(*)               AS request_count,
  AVG(target_response_time) AS avg_response_ms,
  MAX(target_response_time) AS max_response_ms,
  request_url
FROM raw_zone.alb_access_logs
WHERE dt = '2024-01-15'
  AND target_status_code LIKE '5%'
GROUP BY target_status_code, request_url
ORDER BY request_count DESC
LIMIT 20;
```

---

### 12. Schema evolution — add column, check compatibility

An upstream team adds a `loyalty_tier` column to the orders table.

```sql
-- Add column to Iceberg table (non-breaking, backward compatible)
ALTER TABLE processed_zone.orders
ADD COLUMNS (loyalty_tier STRING);

-- Verify schema
DESCRIBE processed_zone.orders;

-- Query with new column (NULLs for old rows)
SELECT order_id, loyalty_tier
FROM processed_zone.orders
WHERE dt = '2024-01-15'
LIMIT 100;
```

---

### 13. Parameterized reporting using prepared statements

A reporting API executes the same query for different customers thousands of times per day.

**Solution:** Use the `get_orders_by_date` prepared statement to avoid SQL injection and reduce parse overhead:

```python
import boto3
client = boto3.client('athena')
client.start_query_execution(
    QueryString="EXECUTE get_orders_by_date USING '2024-01-01', '2024-01-31', 'COMPLETED', '100'",
    WorkGroup="primary",
    ResultConfiguration={"OutputLocation": "s3://results/primary/"}
)
```

---

### 14. ETL pipeline query — CTAS to write processed data to S3

Daily ETL: transform raw CSV orders into partitioned Parquet in the processed zone.

```sql
-- Run in etl_pipelines workgroup (100 GB scan limit)
CREATE TABLE processed_zone.orders_2024_01_15
WITH (
  format              = 'PARQUET',
  parquet_compression = 'SNAPPY',
  partitioned_by      = ARRAY['dt'],
  location            = 's3://prod-data-lake/processed/orders/'
) AS
SELECT
  order_id,
  customer_id,
  CAST(order_amount AS DECIMAL(18,2)) AS order_amount,
  LOWER(status)                       AS status,
  order_ts,
  '2024-01-15'                        AS dt
FROM raw_zone.orders_csv
WHERE ingest_date = '2024-01-15'
  AND order_id IS NOT NULL;
```

---

### 15. Workgroup quota enforcement — stopping runaway queries

An analyst accidentally runs a query without a partition filter, triggering a full-table scan of a 50 TB table.

**Prevention (via this module):**

```hcl
workgroups = {
  primary = {
    enforce_workgroup_configuration    = true    # users cannot override
    bytes_scanned_cutoff_per_query     = 10737418240  # 10 GB hard limit
  }
}
```

Athena immediately cancels any query exceeding 10 GB scanned and returns:

```
CANCELLED: Query exhausted data allowed to be scanned
```

**Reactive:** If a query slips through on an uncapped workgroup, stop it programmatically:

```python
import boto3
athena = boto3.client('athena')
executions = athena.list_query_executions(WorkGroup="data_science")
for qid in executions["QueryExecutionIds"]:
    details = athena.get_query_execution(QueryExecutionId=qid)
    scanned = details["QueryExecution"]["Statistics"].get("DataScannedInBytes", 0)
    if scanned > 50 * 1024**3:  # > 50 GB
        athena.stop_query_execution(QueryExecutionId=qid)
```

---

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `name_prefix` | Prefix for all named resources | `string` | `"prod"` | no |
| `tags` | Default tags merged into all resources | `map(string)` | `{}` | no |
| `workgroups` | Map of workgroup definitions | `map(object(...))` | `{}` | no |
| `databases` | Map of Glue catalog database definitions | `map(object(...))` | `{}` | no |
| `named_queries` | Map of saved named queries | `map(object(...))` | `{}` | no |
| `data_catalogs` | Map of federated data catalog definitions | `map(object(...))` | `{}` | no |
| `prepared_statements` | Map of prepared statement definitions | `map(object(...))` | `{}` | no |
| `capacity_reservations` | Map of capacity reservation definitions | `map(object(...))` | `{}` | no |
| `results_bucket_arns` | S3 bucket ARNs for query results | `list(string)` | `[]` | no |
| `data_lake_bucket_arns` | S3 bucket ARNs for data lake reads | `list(string)` | `[]` | no |
| `results_kms_key_arn` | KMS key ARN for result encryption | `string` | `null` | no |

## Outputs

| Name | Description |
|---|---|
| `workgroup_ids` | Map of workgroup key → ID |
| `workgroup_arns` | Map of workgroup key → ARN |
| `workgroup_names` | Map of workgroup key → name |
| `database_ids` | Map of database key → Glue DB ID |
| `named_query_ids` | Map of named query key → ID |
| `data_catalog_arns` | Map of data catalog key → ARN |
| `prepared_statement_ids` | Map of prepared statement key → ID |
| `capacity_reservation_arns` | Map of capacity reservation key → ARN |
| `athena_analyst_role_arn` | ARN of the Athena analyst IAM role |
| `athena_admin_role_arn` | ARN of the Athena admin IAM role |
| `athena_analyst_policy_json` | Analyst IAM policy JSON (attach to app roles) |
| `s3_results_policy_json` | S3 results bucket access policy JSON |
| `query_templates` | Pre-built SQL query templates map |

---

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3.0 |
| aws | >= 5.0.0 |

---

## License

MIT

