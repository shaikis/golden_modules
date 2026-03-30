# tf-aws-data-e-athena Examples

Runnable examples for the [`tf-aws-data-e-athena`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Production-ready setup with four workgroups (primary, data_science, etl_pipelines, reporting), three Glue catalog databases (raw/processed/analytics), eight named queries, three prepared statements, a federated Lambda data catalog, and a 48-DPU capacity reservation. Demonstrates KMS encryption, per-workgroup scan limits, and full IAM wiring. |

## Architecture

```mermaid
graph LR
    subgraph Sources["Data Sources"]
        S3LAKE["S3 Data Lake\nraw_zone · processed_zone\nanalytics_zone"]
        EXT["External Database\nLambda Federated Connector"]
    end

    subgraph Processing["Athena (complete example)"]
        GCAT["Glue Catalog Databases\nraw_zone · processed_zone\nanalytics_zone"]
        WG1["primary workgroup\n10 GB scan limit\nSSE-KMS"]
        WG2["data_science workgroup\nno scan limit\nSSE-KMS"]
        WG3["etl_pipelines workgroup\n100 GB scan limit\nBUCKET_OWNER ACL"]
        WG4["reporting workgroup\n5 GB scan limit\nSSE-S3"]
        NQ["Named Queries\npreview · repair · revenue\ncost · DQ · optimize · vacuum"]
        PS["Prepared Statements\nget_orders_by_date\nrevenue_by_country\ncustomer_order_history"]
        FED["Federated Catalog\nLAMBDA connector"]
        CAP["Capacity Reservation\n48 DPUs → etl_pipelines"]
    end

    subgraph Destinations["Destinations"]
        RES["S3 Results Bucket\n/primary/ · /data-science/\n/etl-pipelines/ · /reporting/"]
        BI["Consumers\nQuickSight · SageMaker\nboto3 · Tableau"]
    end

    S3LAKE --> GCAT
    EXT --> FED
    FED --> WG2
    GCAT --> WG1
    GCAT --> WG2
    GCAT --> WG3
    GCAT --> WG4
    NQ --> WG1
    NQ --> WG3
    NQ --> WG4
    PS --> WG1
    PS --> WG4
    CAP --> WG3
    WG1 --> RES
    WG2 --> RES
    WG3 --> RES
    WG4 --> RES
    RES --> BI
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="prod.tfvars"
```

### Required variables (`prod.tfvars`)

```hcl
name_prefix          = "prod"
account_id           = "123456789012"
results_bucket_name  = "my-athena-results"
results_bucket_arn   = "arn:aws:s3:::my-athena-results"
results_kms_key_arn  = "arn:aws:kms:us-east-1:123456789012:key/..."
data_lake_bucket_name = "my-data-lake"
data_lake_bucket_arn  = "arn:aws:s3:::my-data-lake"
lambda_connector_arn  = "arn:aws:lambda:us-east-1:123456789012:function:athena-connector"
```
