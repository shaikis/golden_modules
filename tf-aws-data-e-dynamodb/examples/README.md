# tf-aws-data-e-dynamodb Examples

Runnable examples for the [`tf-aws-data-e-dynamodb`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Production e-commerce platform with six DynamoDB tables (users, orders, products, sessions, events, inventory), a three-region global table (orders_global), GSIs/LSIs, TTL, DynamoDB Streams, Kinesis streaming, AWS Backup with cross-region copy, autoscaling for the inventory table, CloudWatch alarms, and IAM roles. |
| [global-table](global-table/) | Dedicated multi-region active-active example with two global tables (user_profiles, sessions_global) replicated across us-east-1, eu-west-1, and ap-southeast-1. Demonstrates replication latency alarms and per-replica PITR settings. |

## Architecture

```mermaid
graph LR
    subgraph Sources["Application Sources"]
        APP["Application Services\nSDK Writes"]
        BATCH["Batch / ETL\nBulk Writes"]
    end

    subgraph Processing["DynamoDB (this module)"]
        USERS["users table\nPAY_PER_REQUEST\nSSE-KMS · PITR · TTL\nStreams: NEW_AND_OLD_IMAGES"]
        ORDERS["orders table\nPAY_PER_REQUEST\nGSI · LSI · Streams"]
        EVENTS["events table\nPAY_PER_REQUEST\nKinesis Streaming · TTL"]
        INV["inventory table\nPROVISIONED\nAutoscaling 5-500 RCU/WCU"]
        GTBL["orders_global\nActive-Active\nus-east-1 · eu-west-1\nap-southeast-1"]
        BACK["AWS Backup\nVault · WORM\nCross-Region Copy"]
        CW["CloudWatch Alarms\nThrottle · Latency\nReplication Lag"]
    end

    subgraph Destinations["Downstream Systems"]
        LAM["Lambda\nStream Event Processor"]
        FH["Kinesis Firehose\n→ S3 Data Lake"]
        S3BK["S3 Backup Vault\nSecondary Region"]
    end

    APP --> USERS
    APP --> ORDERS
    APP --> EVENTS
    APP --> INV
    BATCH --> INV
    USERS --> GTBL
    ORDERS --> GTBL
    USERS --> BACK
    ORDERS --> BACK
    INV --> BACK
    BACK --> S3BK
    USERS --> CW
    ORDERS --> CW
    INV --> CW
    GTBL --> CW
    USERS --> LAM
    ORDERS --> LAM
    EVENTS --> FH
```

## Quick Start

```bash
# Complete e-commerce setup
cd complete/
terraform init
terraform apply -var-file="prod.tfvars"

# Global table multi-region setup
cd global-table/
terraform init
terraform apply -var-file="prod.tfvars"
```

### Required variables for `complete/` (`prod.tfvars`)

```hcl
name_prefix                 = "prod"
kms_key_arn                 = "arn:aws:kms:us-east-1:123456789012:key/..."
alarm_sns_topic_arn         = "arn:aws:sns:us-east-1:123456789012:dynamodb-alerts"
inventory_kinesis_stream_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/inventory-events"
backup_secondary_vault_arn  = "arn:aws:backup:eu-west-1:123456789012:backup-vault/secondary"
```
