# tf-aws-data-e-dms Examples

Runnable examples for the [`tf-aws-data-e-dms`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single replication instance migrating MySQL to PostgreSQL using full-load-and-CDC. Demonstrates the minimum required configuration: subnet group, one replication instance, two endpoints, and one task. |
| [complete](complete/) | Three concurrent migration scenarios: Oracle on-premises to S3 (Parquet CDC), RDS PostgreSQL to Redshift (analytics), and MySQL RDS to Aurora MySQL (homogeneous). Includes CloudWatch alarms, DMS event subscriptions, KMS encryption, and Secrets Manager credential references. |

## Architecture

```mermaid
graph LR
    subgraph Sources["Source Databases (complete example)"]
        ORA["Oracle On-Prem\nport 1521\nLogMiner CDC"]
        PG["PostgreSQL RDS\nport 5432\npglogical CDC"]
        MYSQL["MySQL RDS\nport 3306\nbinlog CDC"]
    end

    subgraph Processing["DMS (this module)"]
        RI_ORA["Replication Instance\noracle-migration\ndms.r5.large · Multi-AZ"]
        RI_PG["Replication Instance\npg-migration\ndms.t3.large · Multi-AZ"]
        RI_MY["Replication Instance\nmysql-migration\ndms.t3.medium"]
        TASK1["Task: oracle-to-s3\nfull-load-and-cdc"]
        TASK2["Task: pg-to-redshift\nfull-load-and-cdc"]
        TASK3["Task: mysql-to-aurora\nfull-load-and-cdc"]
    end

    subgraph Destinations["Target Systems"]
        S3["S3 Data Lake\nParquet · GZIP\nraw landing zone"]
        RS["Amazon Redshift\nanalytics DW\nSSE-KMS staging"]
        AUR["Aurora MySQL\nhomogeneous target"]
        CW["CloudWatch Alarms\nCDC Latency · Table Errors"]
        EVT["SNS Event Subscriptions\nTask + Instance failures"]
    end

    ORA --> RI_ORA --> TASK1 --> S3
    PG --> RI_PG --> TASK2 --> RS
    MYSQL --> RI_MY --> TASK3 --> AUR
    TASK1 --> CW
    TASK2 --> CW
    TASK3 --> CW
    RI_ORA --> EVT
    RI_PG --> EVT
    RI_MY --> EVT
```

## Quick Start

```bash
# Minimal — MySQL → PostgreSQL
cd minimal/
terraform init
terraform apply

# Complete — three-scenario production migration
cd complete/
terraform init
terraform apply -var-file="prod.tfvars"
```

### Required variables for `complete/` (`prod.tfvars`)

```hcl
alarm_sns_topic_arn    = "arn:aws:sns:us-east-1:123456789012:dms-alerts"
kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/..."
oracle_server_name     = "oracle.internal.example.com"
pg_server_name         = "mydb.cluster-xxxx.us-east-1.rds.amazonaws.com"
mysql_server_name      = "mysql.xxxx.us-east-1.rds.amazonaws.com"
aurora_server_name     = "aurora.cluster-xxxx.us-east-1.rds.amazonaws.com"
redshift_server_name   = "my-cluster.xxxx.us-east-1.redshift.amazonaws.com"
s3_landing_bucket      = "my-dms-landing-bucket"
dms_s3_service_role_arn = "arn:aws:iam::123456789012:role/dms-s3-access-role"
```
