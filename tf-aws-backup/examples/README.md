# tf-aws-backup Examples

Runnable examples for the [`tf-aws-backup`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Single vault with a daily backup plan selected by resource tags, optional cross-region copy, SNS notifications, and CloudWatch alarms/dashboard |
| [complete](complete/) | Production setup with vault lock, daily and monthly backup rules, cross-region DR vault (dual-provider), EC2 VSS advanced settings, audit framework with compliance controls, and CSV/JSON report plans |

## Architecture

```mermaid
graph TB
    subgraph Primary["Primary Region"]
        Resources["Tagged AWS Resources\n(EC2, RDS, EFS, DynamoDB, ...)"]
        Selection["Backup Selection\n(tag-based)"]
        Plan["Backup Plan\ndaily cron(0 5 * * ? *)\nmonthly cron(0 7 1 * ? *)"]
        Vault["Primary Vault\n(Vault Lock enabled)"]
        IAMRole["IAM Role\n(AWS Backup service role)"]
    end

    subgraph DR["DR Region"]
        DRVault["DR Vault\n(Vault Lock enabled)"]
    end

    subgraph Observability
        SNS["SNS Topic\n(job notifications)"]
        CW["CloudWatch Alarms\n+ Dashboard"]
        Logs["CloudWatch Logs"]
        Reports["S3 Report Bucket\n(CSV + JSON)"]
    end

    subgraph Governance
        Framework["Audit Framework\n(BACKUP_RECOVERY_POINT_ENCRYPTED\nMINIMUM_RETENTION_CHECK)"]
    end

    Resources --> Selection --> Plan --> Vault
    Vault -- "copy action" --> DRVault
    IAMRole --> Plan
    Vault --> SNS --> CW
    Vault --> Logs
    Framework --> Reports
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```

For the full production setup:

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
