# tf-aws-elasticache Examples

Runnable examples for the [`tf-aws-elasticache`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal Redis replication group with configurable node type, subnet IDs, and optional Multi-AZ/automatic failover — suitable for development environments |

## Architecture

```mermaid
graph TB
    subgraph VPC["VPC"]
        subgraph Subnets["Private Subnets"]
            Primary["Primary Node\n(Redis)"]
            Replica["Replica Node(s)\n(optional Multi-AZ)"]
        end
        SubnetGroup["ElastiCache Subnet Group"]
    end

    App["Application"] --> Primary
    Primary -- "replication" --> Replica
    SubnetGroup --> Primary
    SubnetGroup --> Replica

    Output["redis_primary_endpoint_address"]
    Primary --> Output
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
