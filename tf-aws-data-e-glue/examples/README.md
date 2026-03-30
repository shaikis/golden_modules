# tf-aws-data-e-glue Examples

Runnable examples for the [`tf-aws-data-e-glue`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single Glue ETL job with an auto-created IAM service role. No crawlers, triggers, workflows, or connections. The simplest starting point to get a script running on Glue 4.0. |
| [complete](complete/) | Production daily ETL pipeline: three catalog databases (raw/processed/analytics zones), three crawlers (S3, JDBC/RDS, Delta Lake), five jobs (ingest_raw, transform_orders, aggregate_daily, python_utility, streaming_cdc), one workflow with three triggers (scheduled + conditional), JDBC and Kafka connections, two schema registries (Avro + JSON), KMS security configuration, and catalog encryption. |

## Architecture

```mermaid
graph LR
    subgraph Sources["Data Sources"]
        S3RAW["S3 Raw Zone\norders/ · customers/\ncdc/ micro-batches"]
        RDS["PostgreSQL RDS\nJDBC source\npublic schema"]
        MSK["Amazon MSK\nKafka CDC topic\ndb.public.orders"]
    end

    subgraph Processing["Glue (complete example)"]
        CRAWL_S3["s3_raw_crawler\nS3 targets · CRAWL_NEW_FOLDERS"]
        CRAWL_RDS["rds_jdbc_crawler\nJDBC target · public/%"]
        CRAWL_DL["delta_lake_crawler\nDelta target · write_manifest"]
        CAT["Glue Data Catalog\nraw_zone · processed_zone\nanalytics_zone"]
        WF["Workflow: daily_etl_pipeline\nmax 1 concurrent run"]
        T1["Trigger: start_crawl\nSCHEDULED cron 01:00 UTC"]
        T2["Trigger: after_crawl\nCONDITIONAL → SUCCEEDED"]
        T3["Trigger: after_ingest\nCONDITIONAL → parallel jobs"]
        J1["ingest_raw\nglueetl G.1X x4\nBookmark ENABLED"]
        J2["transform_orders\nglueetl G.2X x8\nJoin orders+customers"]
        J3["aggregate_daily\nglueetl G.1X x4\nFLEX execution"]
        J4["python_utility\npythonshell\npartition repair"]
        J5["streaming_cdc\ngluestreaming G.025X x2\nno timeout"]
        SEC["Security Config\nSSE-KMS all layers"]
        REG["Schema Registries\nAvro BACKWARD\nJSON FORWARD"]
    end

    subgraph Destinations["Destinations"]
        PROC["S3 Processed Zone\nSilver · Parquet/Snappy\npartitioned by date"]
        ANAL["S3 Analytics Zone\nGold · orders_enriched\ndaily_aggregates"]
    end

    S3RAW --> CRAWL_S3 --> CAT
    RDS --> CRAWL_RDS --> CAT
    S3RAW --> CRAWL_DL --> CAT
    MSK --> J5
    CAT --> J1
    CAT --> J2
    CAT --> J3
    T1 --> CRAWL_S3
    T2 --> J1
    T3 --> J2
    T3 --> J3
    WF --> T1
    WF --> T2
    WF --> T3
    SEC --> J1
    SEC --> J2
    SEC --> J3
    SEC --> J5
    REG --> J5
    J1 --> PROC
    J2 --> ANAL
    J3 --> ANAL
    J4 --> CAT
    J5 --> S3RAW
```

## Quick Start

```bash
# Minimal — single ETL job
cd minimal/
terraform init
terraform apply

# Complete — full production pipeline
cd complete/
terraform init
terraform apply -var-file="prod.tfvars"
```

### Required variables for `complete/` (`prod.tfvars`)

```hcl
environment             = "prod"
project                 = "data-platform"
data_lake_bucket_name   = "my-data-lake"
assets_bucket_name      = "my-glue-assets"
glue_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/..."
rds_jdbc_url            = "jdbc:postgresql://mydb.xxxx.us-east-1.rds.amazonaws.com:5432/appdb"
rds_username            = "glue_reader"
rds_password            = "changeme"
rds_subnet_id           = "subnet-0abc123"
rds_security_group_id   = "sg-0abc123"
rds_availability_zone   = "us-east-1a"
msk_bootstrap_servers   = "b-1.msk.xxxx.kafka.us-east-1.amazonaws.com:9092"
msk_subnet_id           = "subnet-0def456"
msk_security_group_id   = "sg-0def456"
```
