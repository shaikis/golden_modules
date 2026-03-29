# tf-aws-kinesis

Production-grade Terraform module for AWS Kinesis — covering **Data Streams**, **Firehose Delivery Streams**, **Data Analytics v2 (Apache Flink)**, enhanced fan-out consumers, IAM roles, and CloudWatch alarms.

---

## Quick Start — minimal setup

```hcl
module "kinesis" {
  source = "github.com/your-org/tf-aws-kinesis"

  kinesis_streams = {
    my_stream = {
      on_demand = true
    }
  }
}
```

One ON_DEMAND stream with KMS encryption. Nothing else created.

## Feature flags

| Flag | Default | What it creates |
|------|---------|-----------------|
| `create_firehose_streams` | `false` | Kinesis Firehose delivery streams (S3/Redshift/OpenSearch/Splunk) |
| `create_analytics_applications` | `false` | Apache Flink (Kinesis Analytics v2) applications |
| `create_stream_consumers` | `false` | Enhanced Fan-Out (EFO) consumers |
| `create_alarms` | `false` | CloudWatch alarms (throttling, iterator age, delivery freshness) |
| `create_iam_roles` | `true` | Scoped IAM roles for producer, consumer, Firehose |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Data Sources / Producers                         │
│   IoT Sensors │ Web Apps │ Mobile SDKs │ CDC (DMS) │ Lambda Functions   │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │  PutRecord / PutRecords
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     Kinesis Data Streams (KDS)                           │
│                                                                          │
│   ┌─────────────┐   ┌─────────────┐   ┌──────────────┐                  │
│   │   events    │   │   orders    │   │  clickstream │                  │
│   │ (ON_DEMAND) │   │ (4 shards)  │   │  (8 shards)  │                  │
│   │  KMS enc.   │   │  168h ret.  │   │  48h ret.    │                  │
│   └──────┬──────┘   └──────┬──────┘   └──────┬───────┘                  │
│          │                 │    ▲             │                          │
│          │           EFO Consumer│            │                          │
│          │         (orders-analytics-efo)     │                          │
└──────────┼─────────────────┼────┼────────────┼──────────────────────────┘
           │                 │    │            │
           ▼                 ▼    │            ▼
┌──────────────────┐  ┌──────────┴───────┐  ┌──────────────────────────────┐
│  Firehose to S3  │  │Firehose→Redshift │  │  Kinesis Data Analytics v2   │
│  ─────────────── │  │  ─────────────── │  │  ─────────────────────────── │
│  • GZIP compress │  │  • Raw orders    │  │  Apache Flink 1.18           │
│  • Dyn partition │  │    table         │  │  • Parallelism = 4           │
│  • Lambda xform  │  │  • S3 backup on  │  │  • Auto-scaling enabled      │
│  • Hive prefixes │  │    failure       │  │  • 60s checkpoints           │
└────────┬─────────┘  └──────────────────┘  │  • Operator metrics          │
         │                                  └──────────────────────────────┘
         ▼
┌────────────────────────────────────────────┐
│  S3 Data Lake                              │
│  events/year=YYYY/month=MM/day=DD/hour=HH/ │
│  (Athena / Glue / EMR queryable)           │
└────────────────────────────────────────────┘

CloudWatch Alarms ──► SNS Topic ──► PagerDuty / Slack / Email
```

---

## Module Structure

```
tf-aws-kinesis/
├── versions.tf       # Provider constraints, data sources for region/account
├── variables.tf      # All input variables
├── outputs.tf        # All outputs
├── streams.tf        # aws_kinesis_stream + aws_kinesis_stream_consumer
├── firehose.tf       # aws_kinesis_firehose_delivery_stream (5 destinations)
├── analytics.tf      # aws_kinesisanalyticsv2_application + snapshot
├── consumers.tf      # Enhanced fan-out helper locals
├── iam.tf            # IAM roles for producer/consumer/firehose/analytics/lambda
├── alarms.tf         # CloudWatch metric alarms
└── examples/
    └── complete/
        ├── versions.tf
        ├── variables.tf
        ├── outputs.tf
        ├── main.tf
        └── prod.tfvars
```

---

## Quick Start

```hcl
module "kinesis" {
  source = "path/to/tf-aws-kinesis"

  name_prefix = "prod-"

  kinesis_streams = {
    events = {
      on_demand        = true
      retention_period = 24
      kms_key_id       = "alias/aws/kinesis"
    }
    orders = {
      shard_count      = 4
      retention_period = 168
      kms_key_id       = "alias/prod/kinesis"
    }
  }

  firehose_streams = {
    events_to_s3 = {
      source_stream_key = "events"
      destination       = "s3"
      s3_config = {
        bucket_arn         = "arn:aws:s3:::my-data-lake"
        compression_format = "GZIP"
        dynamic_partitioning = true
      }
    }
  }

  create_alarms       = true
  alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:alerts"
}
```

---

## Shard Capacity Calculator

Each Kinesis shard supports:
- **Write**: 1 MB/s or 1,000 records/s (whichever is hit first)
- **Read**: 2 MB/s shared across all standard consumers

### Formula

```
Required write shards = max(
  ceil(peak_write_MB_per_second / 1),
  ceil(peak_write_records_per_second / 1000)
)

Required read shards = ceil(
  (peak_read_MB_per_second * number_of_consumers) / 2
)

Final shard count = max(write_shards, read_shards) * safety_factor
```

### Example

| Scenario                    | Producers | Peak write | Records/s | Consumers | Shards needed |
|-----------------------------|-----------|-----------|-----------|-----------|---------------|
| IoT telemetry (1 KB/record) | 5,000     | 5 MB/s    | 5,000     | 1         | 5             |
| Clickstream (500 B/record)  | 100,000   | 50 MB/s   | 100,000   | 2 apps    | 100           |
| CDC events (2 KB/record)    | 1,000     | 2 MB/s    | 1,000     | 3 apps    | 3 (read limit)|

**Rule of thumb**: start with `ceil(peak_MB_per_second)` shards and scale up by 25% for headroom. Use ON_DEMAND for unpredictable traffic.

---

## ON_DEMAND vs PROVISIONED Mode

| Dimension              | ON_DEMAND                          | PROVISIONED                          |
|------------------------|------------------------------------|--------------------------------------|
| Capacity management    | AWS auto-scales                    | You manage shard count               |
| Cost model             | Per GB ingested + per GB retrieved | Per shard-hour                       |
| Max throughput         | Up to 200 MB/s write (soft limit)  | Unlimited (add shards)               |
| Latency to scale       | Minutes (automatic)                | Immediate (pre-provisioned)          |
| Predictable workloads  | More expensive                     | More economical                      |
| Bursty workloads       | Ideal — no capacity planning       | Risk of throttling                   |
| Cold start penalty     | None                               | None                                 |
| When to choose         | New pipelines, unknown growth      | Stable, high-volume, cost-optimized  |

**Cost tip**: ON_DEMAND is roughly 3–5x more expensive per GB than PROVISIONED at high steady-state volume. Switch to PROVISIONED once traffic patterns are known.

---

## Enhanced Fan-Out (EFO)

Enhanced fan-out gives each registered consumer a **dedicated 2 MB/s per shard** push-based connection using `SubscribeToShard`, instead of the shared 2 MB/s pull model.

### Benefits
- No read throttling between consumers — each gets independent throughput
- Lower end-to-end latency (~70ms vs ~200ms for standard consumers)
- Essential when multiple high-throughput consumers read the same stream

### Trade-offs
- Additional cost: ~$0.015/shard-hour per registered consumer
- Maximum 20 EFO consumers per stream
- EFO consumers use `SubscribeToShard` API (push) rather than `GetRecords` (pull)

### Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
stream_consumers = {
  fraud_detection_consumer = {
    stream_key    = "orders"
    consumer_name = "prod-fraud-detection-efo"
  }
  analytics_consumer = {
    stream_key    = "orders"
    consumer_name = "prod-analytics-efo"
  }
}
```

Both consumers receive independent 2 MB/s × 4 shards = 8 MB/s without competing.

---

## Dynamic Partitioning in Firehose

Dynamic partitioning allows Firehose to route records to different S3 prefixes based on record content — enabling Hive-compatible partition layouts without a Lambda.

### How it works

1. Firehose applies a **JQ expression** or **inline parsing** to extract partition keys from each record's JSON body
2. Records are buffered and delivered to per-partition prefixes
3. The S3 prefix uses `!{partitionKeyFromQuery:field}` syntax

### Example prefix

```
data/customer=!{partitionKeyFromQuery:customerId}/
    year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/
```

### Terraform configuration

```hcl
s3_config = {
  bucket_arn           = "arn:aws:s3:::my-lake"
  prefix               = "events/region=!{partitionKeyFromQuery:region}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  dynamic_partitioning = true
  lambda_processor_arn = "arn:aws:lambda:us-east-1:123456789012:function:firehose-transform"
}
```

The Lambda must add a `partitionKeys` field to the transformed record metadata.

---

## Flink Application Deployment Steps

1. **Build the JAR** — package your Flink application with the Kinesis connector:
   ```xml
   <dependency>
     <groupId>org.apache.flink</groupId>
     <artifactId>flink-connector-kinesis</artifactId>
     <version>4.3.0-1.18</version>
   </dependency>
   ```

2. **Upload to S3**:
   ```bash
   aws s3 cp target/my-app-1.0.jar \
     s3://prod-flink-artifacts-123456789/flink-apps/my-app-1.0.jar
   ```

3. **Apply Terraform** with `start_application = false` initially:
   ```bash
   terraform apply -var-file=prod.tfvars
   ```

4. **Update the S3 key in variables** and re-apply when releasing a new version — Terraform will update the application configuration.

5. **Start the application**:
   ```bash
   aws kinesisanalyticsv2 start-application \
     --application-name prod-clickstream-processor \
     --run-configuration '{"ApplicationRestoreConfiguration":{"ApplicationRestoreType":"RESTORE_FROM_LATEST_SNAPSHOT"}}'
   ```
   Or set `start_application = true` in Terraform after the JAR is validated.

6. **Monitor** via CloudWatch metrics:
   - `numRecordsInPerSecond` — ingestion rate
   - `numLateRecordsDropped` — watermark issues
   - `lastCheckpointSize` — checkpoint health
   - `uptime` — application health

---

## Real-World Data Engineering Scenarios

### 1. IoT Telemetry Ingestion
- Devices publish MQTT → IoT Core Rule → `PutRecord` to Kinesis stream
- Firehose buffers and lands raw telemetry to S3 (Parquet via Glue schema)
- Flink processes anomaly detection in real time, outputs alerts to SNS
- **Configuration**: ON_DEMAND stream, Parquet conversion, 24h retention

### 2. Clickstream Analytics
- Web SDK sends events to API Gateway → Lambda → `PutRecords` (batched)
- Flink computes session windows, funnel metrics, and real-time CTR
- Results written to DynamoDB (hot path) and S3 (cold path via Firehose)
- **Configuration**: 8-shard PROVISIONED stream, EFO for Flink consumer

### 3. Change Data Capture (CDC)
- AWS DMS replicates database transactions to Kinesis stream
- Firehose delivers raw CDC to S3 for audit trail (GZIP, 7-day retention)
- Flink applies schema normalization and upserts to OpenSearch for search
- **Configuration**: `orders` stream with 168h retention, multiple consumers

### 4. Real-Time Fraud Detection
- Payment events stream into Kinesis with PCI-compliant KMS encryption
- Flink sliding window joins on card/IP/device fingerprints
- Fraud signals published to SNS → Lambda → block list DynamoDB table
- **Configuration**: EFO consumer for fraud engine, iterator age alarm < 5s

### 5. Real-Time Personalization
- User interaction events (views, clicks, add-to-cart) ingested via Kinesis
- Flink aggregates feature vectors per user in 5-minute tumbling windows
- Feature store (DynamoDB) updated for sub-10ms recommendation serving
- **Configuration**: ON_DEMAND stream, Flink parallelism = 8

### 6. Log Aggregation and SIEM
- Application and VPC flow logs → Kinesis stream via CloudWatch Logs subscription
- Firehose delivers to Splunk (HEC endpoint) for real-time SIEM ingestion
- S3 backup retained 90 days for compliance forensics
- **Configuration**: Splunk destination Firehose, SSE-KMS encryption

### 7. Multi-Region Event Replication
- Primary Kinesis stream in us-east-1
- Lambda consumer replicates records to Kinesis in eu-west-1 (GDPR region)
- Regional Firehose pipelines deliver to local S3 data lakes
- **Configuration**: EFO consumer for replication Lambda, low iterator age threshold

### 8. Microservices Event Bus
- Services emit domain events to dedicated Kinesis streams (one per bounded context)
- EFO consumers for each downstream service — fully decoupled throughput
- Firehose archives all events to S3 for event sourcing replay
- **Configuration**: Multiple PROVISIONED streams with `enforce_consumer_deletion = false`

### 9. Financial Market Data Distribution
- Exchange feed → Kinesis with 1ms latency target
- EFO consumers for trading engines, risk systems, compliance recorders
- Flink computes VWAP, spreads, and price alerts in real time
- **Configuration**: EFO mandatory (shared read would throttle), parallelism tuned per shard

### 10. Data Lakehouse Ingestion
- Raw events land in S3 via Firehose (GZIP, Hive-partitioned prefixes)
- Glue Crawler catalogs new partitions hourly
- Athena / EMR / Spark query directly; Iceberg compaction job runs nightly
- **Configuration**: Parquet conversion enabled, Glue database + table, dynamic partitioning

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix applied to all resource names | `string` | `""` | no |
| `tags` | Default tags merged into every resource | `map(string)` | `{}` | no |
| `kinesis_streams` | Map of Kinesis Data Stream definitions | `map(object)` | `{}` | no |
| `stream_consumers` | Map of enhanced fan-out consumer definitions | `map(object)` | `{}` | no |
| `firehose_streams` | Map of Firehose delivery stream definitions | `map(object)` | `{}` | no |
| `analytics_applications` | Map of Flink application definitions | `map(object)` | `{}` | no |
| `create_alarms` | Whether to create CloudWatch alarms | `bool` | `true` | no |
| `alarm_sns_topic_arn` | SNS topic ARN for alarm notifications | `string` | `null` | no |
| `iterator_age_threshold_ms` | IteratorAge alarm threshold in milliseconds | `number` | `60000` | no |
| `firehose_freshness_threshold_seconds` | DataFreshness alarm threshold in seconds | `number` | `900` | no |
| `create_producer_role` | Whether to create the producer IAM role | `bool` | `true` | no |
| `create_consumer_role` | Whether to create the consumer IAM role | `bool` | `true` | no |
| `create_firehose_role` | Whether to create the Firehose IAM role | `bool` | `true` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `stream_arns` | Map of stream key → ARN |
| `stream_names` | Map of stream key → stream name |
| `consumer_arns` | Map of consumer key → EFO consumer ARN |
| `firehose_arns` | Map of firehose key → delivery stream ARN |
| `firehose_names` | Map of firehose key → delivery stream name |
| `analytics_application_arns` | Map of analytics key → Flink app ARN |
| `producer_role_arn` | ARN of the producer IAM role |
| `consumer_role_arn` | ARN of the consumer IAM role |
| `firehose_role_arn` | ARN of the Firehose delivery IAM role |
| `analytics_role_arns` | Map of analytics key → execution role ARN |
| `alarm_ids` | Map of all CloudWatch alarm resource IDs |
| `alarm_arns` | Map of all CloudWatch alarm ARNs |

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws provider | >= 5.0.0 |

---

## Important Lifecycle Notes

**Kinesis stream recreation is destructive** — all data in the stream is lost:
- Changing the stream **name** forces recreation
- Changing `encryption_type` between `NONE` and `KMS` is an in-place update
- Switching `stream_mode` between `ON_DEMAND` and `PROVISIONED` is in-place

For production workloads, uncomment the `lifecycle { prevent_destroy = true }` block in `streams.tf` to prevent accidental data loss.

---

## Security Considerations

- All streams use KMS encryption by default (`alias/aws/kinesis`)
- Use customer-managed KMS keys (`aws_kms_key`) for FIPS compliance and key rotation control
- Firehose role uses `sts:ExternalId` condition to prevent confused deputy attacks
- IAM roles use least-privilege policies scoped to specific stream ARNs
- Redshift passwords should be stored in AWS Secrets Manager, not in tfvars files
- Enable VPC configuration for Flink applications processing sensitive data

---

## License

MIT — see LICENSE file.

