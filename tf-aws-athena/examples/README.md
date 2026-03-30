# tf-aws-athena Examples

Runnable examples for the [`tf-aws-athena`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Full configuration with 4 workgroups (primary, data-science, etl-pipelines, reporting), 3 databases (raw/processed/analytics zones), 8 named queries, 3 prepared statements, 1 federated Lambda data catalog, 1 capacity reservation, and KMS-encrypted result storage |

## Architecture

```mermaid
graph TB
    subgraph DataLake["S3 Data Lake"]
        RawBucket["raw/"]
        ProcessedBucket["processed/"]
        AnalyticsBucket["analytics/"]
    end

    subgraph Athena["Amazon Athena"]
        subgraph Workgroups
            WG1["primary\n10 GB scan limit, SSE-KMS"]
            WG2["data-science\nno scan limit"]
            WG3["etl-pipelines\n100 GB limit, ACL"]
            WG4["reporting\n5 GB limit, SSE-S3"]
        end

        subgraph Databases
            DB1["raw_zone"]
            DB2["processed_zone"]
            DB3["analytics_zone"]
        end

        subgraph Queries
            NQ["Named Queries\n(preview, repair, revenue,\ntop customers, optimize, vacuum)"]
            PS["Prepared Statements\n(orders by date, revenue by country,\ncustomer history)"]
        end

        CapRes["Capacity Reservation\n48 DPUs — etl-pipelines"]
    end

    subgraph Catalog["Data Catalog"]
        FedCatalog["Federated Lambda Catalog"]
        Lambda["Lambda Connector"]
    end

    ResultsBucket["S3 Results Bucket\n(KMS-encrypted)"]
    KMS["AWS KMS"]

    RawBucket --> DB1
    ProcessedBucket --> DB2
    AnalyticsBucket --> DB3

    WG1 --> ResultsBucket
    WG2 --> ResultsBucket
    WG3 --> ResultsBucket
    WG4 --> ResultsBucket

    FedCatalog --> Lambda
    KMS --> ResultsBucket
    KMS --> Workgroups
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
