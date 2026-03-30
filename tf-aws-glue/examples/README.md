# tf-aws-glue Examples

Runnable examples for the [`tf-aws-glue`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single ETL job with an auto-created IAM role — no crawlers, triggers, workflows, or connections |
| [complete](complete/) | Production-grade daily ETL pipeline with 3 catalog databases, 5 jobs (ETL/pythonshell/streaming), 3 crawlers (S3/JDBC/Delta Lake), 1 workflow, 3 triggers, 2 schema registries, JDBC/Kafka connections, and KMS security configuration |

## Architecture

```mermaid
graph TB
    subgraph Sources
        S3Raw["S3 Raw Zone"]
        RDS["RDS PostgreSQL"]
        MSK["MSK Kafka"]
    end

    subgraph Glue["AWS Glue"]
        Crawler1["S3 Raw Crawler"]
        Crawler2["RDS JDBC Crawler"]
        Crawler3["Delta Lake Crawler"]

        IngestRaw["Job: ingest_raw\n(glueetl G.1X)"]
        TransformOrders["Job: transform_orders\n(glueetl G.2X)"]
        AggregateDaily["Job: aggregate_daily\n(glueetl FLEX)"]
        PythonUtil["Job: python_utility\n(pythonshell)"]
        StreamingCDC["Job: streaming_cdc\n(gluestreaming)"]

        Workflow["Workflow: daily_etl_pipeline"]
        TriggerScheduled["Trigger: start_crawl\ncron 01:00 UTC"]
        TriggerAfterCrawl["Trigger: after_crawl\nCONDITIONAL"]
        TriggerAfterIngest["Trigger: after_ingest\nCONDITIONAL"]
    end

    subgraph Catalog["Glue Data Catalog"]
        DBRaw["DB: raw_zone"]
        DBProcessed["DB: processed_zone"]
        DBAnalytics["DB: analytics_zone"]
        Registry["Schema Registries\n(Avro + JSON)"]
    end

    subgraph Output
        S3Processed["S3 Processed Zone"]
        S3Analytics["S3 Analytics Zone"]
    end

    S3Raw --> Crawler1 --> DBRaw
    RDS --> Crawler2 --> DBRaw
    S3Processed --> Crawler3 --> DBProcessed
    MSK --> StreamingCDC --> S3Raw

    TriggerScheduled --> Crawler1
    TriggerAfterCrawl --> IngestRaw
    TriggerAfterIngest --> TransformOrders
    TriggerAfterIngest --> AggregateDaily

    IngestRaw --> S3Processed
    TransformOrders --> S3Analytics
    AggregateDaily --> S3Analytics

    Workflow --> TriggerScheduled
    Workflow --> TriggerAfterCrawl
    Workflow --> TriggerAfterIngest
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply
```

For the complete example:

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
