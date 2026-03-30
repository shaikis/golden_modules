# tf-aws-data-e-batch Examples

Runnable examples for the [`tf-aws-data-e-batch`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single Fargate Spot compute environment, one default job queue, and one simple ETL job definition. Ideal for getting started or development workloads. IAM roles are auto-created. |
| [complete](complete/) | Production-grade setup with three compute environments (Fargate Spot, EC2 Spot GPU, EC2 On-Demand), three priority-tiered job queues, five job definitions (ETL, ML training, data quality, report generation, GPU inference), fair-share scheduling, and CloudWatch alarms. |

## Architecture

```mermaid
graph LR
    subgraph Sources["Job Inputs"]
        ECR["ECR\nContainer Images"]
        S3IN["S3 Input Data\nRaw / Processed"]
        SF["Step Functions\nor EventBridge"]
    end

    subgraph Processing["AWS Batch (this module)"]
        SCHED["Fair-Share Scheduling\nhigh · normal · low weights"]
        HQ["high-priority-queue\npriority=100\nEC2 On-Demand + Fargate Spot"]
        NQ["normal-queue\npriority=50\nFargate Spot + EC2 On-Demand"]
        LQ["low-priority-queue\npriority=10\nFargate Spot only"]
        CE1["Fargate Spot CE\nServerless · max 512 vCPUs"]
        CE2["EC2 Spot GPU CE\np3/g4dn · max 256 vCPUs"]
        CE3["EC2 On-Demand CE\nm5 family · max 128 vCPUs"]
    end

    subgraph Jobs["Job Definitions"]
        ETL["etl-container-job\n2 vCPU · 4 GB"]
        ML["ml-training-job\n8 vCPU · 60 GB · 1 GPU"]
        DQ["data-quality-job\n1 vCPU · 2 GB"]
        RPT["report-generation-job\n2 vCPU · 4 GB"]
        INF["gpu-ml-inference-job\n4 vCPU · 30 GB · 1 GPU"]
    end

    subgraph Destinations["Outputs"]
        S3OUT["S3 Output\nResults · Models · Reports"]
        CW["CloudWatch Alarms\nFailed / Pending Jobs"]
    end

    ECR --> ETL
    ECR --> ML
    ECR --> DQ
    ECR --> RPT
    ECR --> INF
    SF --> HQ
    SF --> NQ
    SF --> LQ
    SCHED --> HQ
    SCHED --> NQ
    SCHED --> LQ
    S3IN --> ETL
    S3IN --> DQ
    HQ --> CE3
    HQ --> CE1
    NQ --> CE1
    NQ --> CE3
    LQ --> CE1
    CE2 --> ML
    CE2 --> INF
    ETL --> S3OUT
    ML --> S3OUT
    DQ --> S3OUT
    RPT --> S3OUT
    CE1 --> CW
    CE2 --> CW
    CE3 --> CW
```

## Quick Start

```bash
# Minimal — Fargate Spot ETL job
cd minimal/
terraform init
terraform apply

# Complete — multi-tier production setup
cd complete/
terraform init
terraform apply -var-file="prod.tfvars"
```

### Required variables for `complete/` (`prod.tfvars`)

```hcl
subnet_ids          = ["subnet-0abc123", "subnet-0def456"]
security_group_ids  = ["sg-0abc123"]
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:batch-alerts"
ecr_account_id      = "123456789012"
aws_region          = "us-east-1"
```
