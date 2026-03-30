# tf-aws-restore Examples

Runnable examples for the [`tf-aws-restore`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | IAM role with configurable per-service restore permissions (EC2, RDS, EFS, EBS, DynamoDB, FSx, Redshift, S3), optional weekly restore testing plan for EC2 snapshots, CloudWatch alarms, and SNS notifications |
| [complete](complete/) | Full restore configuration with weekly snapshot and monthly PITR testing plans, restore testing selections for EC2, RDS (snapshot + PITR), EFS, and DynamoDB, CloudWatch logs and dashboard |

## Architecture

```mermaid
graph TB
    subgraph BackupVaults["AWS Backup Vaults"]
        Vault["Backup Vault\n(recovery points)"]
    end

    subgraph RestoreTesting["Restore Testing"]
        WeeklyPlan["Weekly Plan\nLATEST_WITHIN_WINDOW\ncron SUN 06:00"]
        MonthlyPlan["Monthly PITR Plan\nRANDOM_WITHIN_WINDOW\ncron 1st of month"]

        EC2Test["EC2 Selection\n(tag: RestoreTest=true)"]
        RDSTest["RDS Selection\n(snapshot restore)"]
        RDSPITRTest["RDS PITR Selection\n(point-in-time)"]
        EFSTest["EFS Selection\n(new filesystem)"]
        DynamoTest["DynamoDB Selection\n(new table)"]
    end

    subgraph IAM["IAM"]
        Role["Restore IAM Role\n(per-service permissions:\nEC2, RDS, EFS, EBS,\nDynamoDB, FSx, Redshift, S3)"]
    end

    subgraph Observability
        SNS["SNS Topic"]
        CWAlarms["CloudWatch Alarms\n(restore job failures)"]
        CWLogs["CloudWatch Logs"]
        Dashboard["CloudWatch Dashboard"]
    end

    Vault --> WeeklyPlan --> EC2Test
    Vault --> WeeklyPlan --> RDSTest
    Vault --> WeeklyPlan --> EFSTest
    Vault --> WeeklyPlan --> DynamoTest
    Vault --> MonthlyPlan --> RDSPITRTest

    Role --> WeeklyPlan
    Role --> MonthlyPlan

    CWAlarms --> SNS
    CWLogs --> Dashboard
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```

For the full multi-service restore testing setup:

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
