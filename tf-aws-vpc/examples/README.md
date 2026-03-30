# tf-aws-vpc Examples

Runnable examples for the [`tf-aws-vpc`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — public and private subnets across AZs with a single NAT gateway |
| [complete](complete/) | Full configuration with public, private, and database subnet tiers, VPN gateway, S3/DynamoDB gateway endpoints, interface endpoints, VPC Flow Logs to CloudWatch with KMS encryption, and DNS settings |

## Architecture

```mermaid
graph TB
    subgraph VPC["VPC (10.0.0.0/16)"]
        subgraph AZ1["Availability Zone A"]
            PubA["Public Subnet"]
            PrivA["Private Subnet"]
            DbA["Database Subnet\n(complete only)"]
        end
        subgraph AZ2["Availability Zone B"]
            PubB["Public Subnet"]
            PrivB["Private Subnet"]
            DbB["Database Subnet\n(complete only)"]
        end

        IGW["Internet Gateway"]
        NGW["NAT Gateway"]
        PubRT["Public Route Table"]
        PrivRT["Private Route Table"]

        S3EP["S3 Gateway Endpoint\n(complete only)"]
        DDBep["DynamoDB Gateway Endpoint\n(complete only)"]
        VPNGW["VPN Gateway\n(complete only)"]
        FL["Flow Logs → CloudWatch\n(complete only)"]
    end

    Internet((Internet)) --> IGW
    IGW --> PubRT
    PubRT --> PubA
    PubRT --> PubB
    NGW --> PrivRT
    PrivRT --> PrivA
    PrivRT --> PrivB
    PubA --> NGW
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
