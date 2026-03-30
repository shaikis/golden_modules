# tf-aws-s3-storage-lens Examples

Runnable examples for the [`tf-aws-s3-storage-lens`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — creates an S3 Storage Lens configuration with account-level and bucket-level activity metrics, advanced cost optimization metrics, prefix-level storage metrics, CloudWatch export, and CSV export to a dedicated S3 reports bucket |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-s3-storage-lens basic example"
        LENS["S3 Storage Lens\nConfiguration"]
        ACCT["Account-Level Metrics\n(activity + cost optimization)"]
        BKT["Bucket-Level Metrics\n(activity + cost optimization)"]
        PFX["Prefix-Level\nStorage Metrics"]

        LENS --> ACCT
        ACCT --> BKT
        BKT --> PFX
    end

    subgraph "Data Export"
        CW["CloudWatch Metrics"]
        RPT["S3 Reports Bucket\n(CSV / SSE-S3)"]
    end

    LENS -->|CloudWatch export| CW
    LENS -->|S3 export — storage-lens/ prefix| RPT
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
