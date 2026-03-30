# tf-aws-efs Examples

Runnable examples for the [`tf-aws-efs`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — creates an encrypted EFS file system with mount targets, a managed security group, and optional lifecycle/backup policies and cross-region replication |
| [complete](complete/) | Full configuration with access points, NFS and EFS-utils mount helpers, cross-region replication, backup policy, and all lifecycle transition options |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-efs complete example"
        EFS["Amazon EFS\nFile System"]
        MT["Mount Targets\n(per subnet)"]
        SG["Security Group"]
        AP["Access Points"]
        BP["Backup Policy\n(AWS Backup)"]
        REP["Cross-Region\nReplication"]

        SG -->|controls NFS 2049| MT
        MT --> EFS
        EFS --> AP
        EFS --> BP
        EFS --> REP
    end

    VPC["VPC / Subnets"] --> MT
    EC2["EC2 / ECS / Lambda"] -->|mount via NFS or efs-utils| MT
    DR["DR Region"] --> REP
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
