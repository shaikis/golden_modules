# tf-aws-dynamodb Examples

Runnable examples for the [`tf-aws-dynamodb`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Full e-commerce platform — 6 tables with GSI/LSI, autoscaling, PITR, KMS, Streams, CloudWatch alarms, and AWS Backup |
| [global-table](global-table/) | Multi-region active-active Global Tables replicated across us-east-1, eu-west-1, and ap-southeast-1 |

## Architecture

```mermaid
graph TB
    subgraph Complete["complete/ — E-Commerce Platform"]
        style Complete fill:#FF9900,color:#232F3E
        T1["users table\nPAY_PER_REQUEST + GSI\nStreams + PITR + KMS"]
        T2["orders table\nGSI (user-orders-index)\nStreams + PITR"]
        T3["products table\nGSI (category-price-index)"]
        T4["sessions table\nSTANDARD_IA + TTL"]
        T5["inventory table\nPROVISIONED + Autoscaling"]
        T6["events table\nKinesis Streaming → Firehose"]
    end

    subgraph GlobalTable["global-table/ — Multi-Region"]
        style GlobalTable fill:#232F3E,color:#FFFFFF
        USE1["us-east-1\n(primary write)"]
        EUW1["eu-west-1\n(replica)"]
        APS1["ap-southeast-1\n(replica)"]
        USE1 <--> EUW1
        USE1 <--> APS1
    end

    BKP["AWS Backup Vault\n(WORM lock + cross-region copy)"]
    CW["CloudWatch Alarms\nThrottle / p99 Latency\nReplication Lag"]
    IAM["IAM Roles\nread-only / read-write\nstream-consumer"]

    Complete --> BKP & CW & IAM
    GlobalTable --> CW
```

## Quick Start

```bash
# Complete e-commerce example
cd complete/
terraform init
terraform apply -var-file="terraform.tfvars"

# Global table example
cd global-table/
terraform init
terraform apply -var-file="terraform.tfvars"
```
