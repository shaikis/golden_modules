# tf-aws-data-e-emr Examples

Runnable examples for the [`tf-aws-data-e-emr`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — single transient Spark cluster that runs a PySpark ETL step and auto-terminates on completion |
| [complete](complete/) | Full configuration with a long-running Spark cluster, transient Hive cluster, two EMR Serverless applications (Spark + Hive), an EMR Studio, KMS-backed security configuration, and CloudWatch alarms |

## Architecture

```mermaid
graph LR
    subgraph Sources["Input Sources"]
        S3IN["S3 Raw Data"]
        SCRIPTS["S3 Scripts\n(bootstrap · steps)"]
    end
    subgraph Processing["Amazon EMR"]
        CLUSTER["EMR Cluster\n(Master · Core · Task nodes)"]
        SERVERLESS["EMR Serverless\n(Spark · Hive)"]
        STUDIO["EMR Studio\n(notebooks)"]
    end
    subgraph Destinations["Output"]
        S3OUT["S3 Processed Data"]
        LOGS["S3 / CloudWatch\n(logs · alarms)"]
    end
    S3IN --> CLUSTER
    S3IN --> SERVERLESS
    SCRIPTS --> CLUSTER
    CLUSTER --> S3OUT
    SERVERLESS --> S3OUT
    CLUSTER --> LOGS
    STUDIO --> CLUSTER
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply -var-file="dev.tfvars"
```
