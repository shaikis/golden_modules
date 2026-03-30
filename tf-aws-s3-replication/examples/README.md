# tf-aws-s3-replication Examples

Runnable examples for the [`tf-aws-s3-replication`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [srr](srr/) | Same-Region Replication — creates a source bucket with SRR to a backup bucket in the same region, KMS encryption, AWS Backup, and lifecycle rules |
| [complete](complete/) | Full configuration with SRR, multi-destination Cross-Region Replication (US West + EU West), AWS Backup, Object Lock, and per-prefix replication filters across three AWS regions |

## Architecture

```mermaid
graph TB
    subgraph "Primary Region"
        KMS_P["KMS Key\n(primary)"]
        SRC["Source S3 Bucket\n(versioning enabled)"]
        SRR["SRR Replica Bucket\n(same region backup)"]
        BACKUP["AWS Backup Vault"]

        KMS_P --> SRC
        SRC -->|same-region replication| SRR
        SRC -->|scheduled backup| BACKUP
    end

    subgraph "DR Region — US West"
        KMS_W["KMS Key\n(dr_west)"]
        DR_W["DR S3 Bucket\n(STANDARD_IA)"]
        KMS_W --> DR_W
    end

    subgraph "DR Region — EU West"
        KMS_E["KMS Key\n(dr_eu)"]
        DR_E["DR S3 Bucket\n(GLACIER — critical/ only)"]
        KMS_E --> DR_E
    end

    SRC -->|CRR all objects| DR_W
    SRC -->|CRR prefix filter: critical/| DR_E
```

## Quick Start

```bash
# Same-region replication only
cd srr/
terraform init
terraform apply -var-file="dev.tfvars"

# Full multi-region setup
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
