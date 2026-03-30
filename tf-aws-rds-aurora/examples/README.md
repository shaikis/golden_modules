# tf-aws-rds-aurora Examples

Runnable examples for the [`tf-aws-rds-aurora`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — Aurora cluster with engine, instance class, subnet group, KMS encryption, and configurable instance count |
| [complete](complete/) | Full configuration with a Global Database spanning primary and DR regions, Aurora Serverless v2 cluster, read-replica auto-scaling, Performance Insights, cluster parameter group, and region-specific KMS keys |

## Architecture

```mermaid
graph TB
    subgraph Primary["Primary Region"]
        Global["Aurora Global Cluster"]
        PrimaryCluster["Primary Aurora Cluster\n(writer + readers)"]
        Scaling["Read Replica\nAuto-Scaling"]
        PI["Performance Insights"]
        KMSp["KMS Key (primary)"]
    end

    subgraph DR["DR Region"]
        DRCluster["DR Aurora Cluster\n(secondary, read-only)"]
        KMSd["KMS Key (DR)"]
    end

    subgraph Serverless["Serverless v2 (primary region)"]
        SLCluster["Aurora Serverless v2\n(0.5–32 ACUs)"]
    end

    Global --> PrimaryCluster
    Global --> DRCluster
    PrimaryCluster --> Scaling
    PrimaryCluster --> PI
    KMSp -->|encryption| PrimaryCluster
    KMSd -->|encryption| DRCluster
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
