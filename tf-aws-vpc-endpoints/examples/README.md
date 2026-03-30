# tf-aws-vpc-endpoints Examples

Runnable examples for the [`tf-aws-vpc-endpoints`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — create gateway and interface VPC endpoints using variable-driven endpoint definitions with shared subnet and security group defaults |

## Architecture

```mermaid
graph TB
    subgraph VPC["VPC"]
        subgraph PrivateSubnets["Private Subnets"]
            SG["Default Security Group(s)"]
        end

        subgraph GatewayEPs["Gateway Endpoints (free)"]
            S3GW["S3 Gateway Endpoint"]
            DDBGW["DynamoDB Gateway Endpoint"]
        end

        subgraph InterfaceEPs["Interface Endpoints (ENI-based)"]
            SSMEP["ssm"]
            SSMMSGS["ssmmessages"]
            EC2EP["ec2"]
            EC2MSGS["ec2messages"]
            LOGSEP["logs"]
            SECREP["secretsmanager"]
        end

        RT["Route Table(s)"]
    end

    PrivateSubnets --> InterfaceEPs
    RT --> GatewayEPs
    SG --> InterfaceEPs

    S3GW -->|"private route"| S3["AWS S3"]
    DDBGW -->|"private route"| DDB["AWS DynamoDB"]
    SSMEP --> SSM["AWS SSM"]
    SECREP --> SM["AWS Secrets Manager"]
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
