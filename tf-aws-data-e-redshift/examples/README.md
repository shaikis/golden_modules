# tf-aws-data-e-redshift Examples

Runnable examples for the [`tf-aws-data-e-redshift`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single provisioned cluster with default settings — fastest path to a working Redshift cluster |
| [complete](complete/) | Production-grade deployment: provisioned clusters (prod + dev), Redshift Serverless, parameter groups, snapshot schedules, scheduled pause/resume/resize, data sharing, and CloudWatch alarms |

## Architecture

```mermaid
graph LR
    subgraph Ingestion["Data Ingestion"]
        S3["S3 Data Lake"]
        FIREHOSE["Kinesis Firehose"]
        AURORA_SRC["Aurora / RDS"]
    end

    subgraph Provisioned["Provisioned Cluster (aws_redshift_cluster)"]
        COPY_CMD["COPY Command\n(batch load)"]
        SPECTRUM["Redshift Spectrum\n(query S3 via Glue Catalog)"]
        FEDERATED["Federated Query\n(live RDS data)"]
        DW["Data Warehouse\nSQL Queries"]
        UNLOAD_CMD["UNLOAD Command\n(export to S3)"]

        COPY_CMD --> DW
        SPECTRUM --> DW
        FEDERATED --> DW
        DW --> UNLOAD_CMD
    end

    subgraph Serverless["Redshift Serverless (optional)"]
        NS["Namespace"] --> WG["Workgroup\n(RPU auto-scale)"]
    end

    subgraph Sharing["Data Sharing"]
        PROD_CLUSTER["Producer Cluster"] -->|live data, no movement| CONS_ACCOUNT["Consumer Account"]
    end

    subgraph Ops["Operations"]
        SCHED_PAUSE["Scheduled Pause/Resume\n(cost saving)"]
        SNAP_SCHED["Snapshot Schedule\n(automated DR)"]
        CW_ALARM["CloudWatch Alarms\n(CPU / connections / latency)"]
    end

    S3 --> COPY_CMD
    FIREHOSE --> S3
    AURORA_SRC --> FEDERATED
    GLUE["Glue Data Catalog"] --> SPECTRUM
    UNLOAD_CMD --> S3

    SCHED_PAUSE --> Provisioned
    SNAP_SCHED --> Provisioned
    CW_ALARM --> Provisioned
```

## Quick Start

```bash
# Minimal — single cluster, default settings
cd minimal/
terraform init
terraform apply

# Complete — production + dev clusters, serverless, all features
cd complete/
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## Feature Comparison

| Feature | minimal | complete |
|---------|---------|----------|
| Provisioned cluster | 1 (dev defaults) | 2 (prod ra3.4xlarge + dev dc2.large) |
| Redshift Serverless | No | Yes (adhoc namespace + workgroup) |
| Parameter groups | No | Yes (prod strict SSL + dev relaxed) |
| Snapshot schedules | No | Yes (daily prod snapshots) |
| Scheduled pause/resume | No | Yes (dev off-hours + prod weekend resize) |
| Data sharing | No | Yes (producer authorization) |
| CloudWatch alarms | No | Yes (CPU, connections, latency, disk) |
| KMS encryption | AWS-managed | Customer-managed (BYO key) |
