# tf-aws-data-e-datasync Examples

Runnable examples for the [`tf-aws-data-e-datasync`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — S3-to-S3 cross-account data copy with a single CHANGED-mode sync task |
| [complete](complete/) | Full configuration with on-premises NFS-to-S3 raw ingestion, S3 raw-to-Glacier archive, EFS-to-S3 backup, nightly cron schedules, task reports, CloudWatch alarms, and bandwidth throttling |

## Architecture

```mermaid
graph LR
    subgraph Sources["Data Sources"]
        NFS["On-Prem NFS\n(192.168.x.x)"]
        EFS["Amazon EFS"]
        S3SRC["S3 Raw Zone"]
    end
    subgraph Processing["AWS DataSync"]
        AGENT["DataSync Agent"]
        TASK["Sync Tasks\n(scheduled · CHANGED · ALL)"]
    end
    subgraph Destinations["Destinations"]
        S3RAW["S3 Raw Zone\n(/incoming/)"]
        S3ARC["S3 Archive\n(Glacier)"]
        S3BCK["S3 Backup\n(Standard-IA)"]
    end
    NFS --> AGENT --> TASK
    EFS --> TASK
    S3SRC --> TASK
    TASK --> S3RAW
    TASK --> S3ARC
    TASK --> S3BCK
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply -var-file="dev.tfvars"
```
