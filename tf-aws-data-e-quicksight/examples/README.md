# tf-aws-data-e-quicksight Examples

Runnable examples for the [`tf-aws-data-e-quicksight`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — IAM role and S3 bucket policy granting QuickSight access to an Athena data lake |
| [complete](complete/) | Full configuration with Athena and Redshift data sources, SPICE datasets with row-level security, KMS encryption, VPC connection for private data sources, and dashboard publishing |

## Architecture

```mermaid
graph LR
    subgraph Sources["Data Sources"]
        ATH["Amazon Athena\n(S3 Data Lake)"]
        RS["Amazon Redshift\n(Data Warehouse)"]
        RDS["Amazon RDS / Aurora"]
    end
    subgraph Processing["Amazon QuickSight"]
        DS["Data Source\n(connection)"]
        DT["Dataset\n(SPICE · transforms · RLS)"]
        DASH["Dashboard\n(analyses · visuals)"]
    end
    subgraph Destinations["Consumers"]
        READERS["Dashboard Readers"]
        WEBAPP["Embedded\nWeb App"]
    end
    Sources --> DS
    DS --> DT
    DT --> DASH
    DASH --> READERS
    DASH --> WEBAPP
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply -var-file="dev.tfvars"
```
