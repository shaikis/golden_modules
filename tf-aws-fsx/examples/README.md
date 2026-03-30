# tf-aws-fsx Examples

Runnable examples for the [`tf-aws-fsx`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Full configuration — deploys FSx file systems (Windows, Lustre, ONTAP, OpenZFS) with KMS encryption, AWS Backup, and optional cross-region backup for ONTAP |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-fsx complete example"
        KMS["tf-aws-kms\n(KMS Key)"]
        FSX["tf-aws-fsx"]

        subgraph "FSx File System Types"
            WIN["FSx for Windows"]
            LUS["FSx for Lustre"]
            ONT["FSx for ONTAP"]
            ZFS["FSx for OpenZFS"]
        end

        BACKUP["AWS Backup\n(Scheduled Snapshots)"]
        CRB["Cross-Region Backup Vault\n(DR Region)"]

        KMS -->|kms_key_arn| FSX
        FSX --> WIN
        FSX --> LUS
        FSX --> ONT
        FSX --> ZFS
        ONT -->|enable_ontap_backup| BACKUP
        BACKUP -->|enable_ontap_cross_region_backup| CRB
    end
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
