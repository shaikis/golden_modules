# tf-aws-security-group Examples

Runnable examples for the [`tf-aws-security-group`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Single security group in a VPC with configurable ingress rules, standard tagging, and no egress restrictions |

## Architecture

```mermaid
graph TB
    subgraph VPC["AWS VPC"]
        subgraph SG["Security Group"]
            INGRESS["Ingress Rules\n(port / protocol / source)"]
            EGRESS["Egress Rules\n(all traffic — default)"]
        end
        EC2["EC2 / ECS / RDS\n(attached resource)"]
    end

    CALLER["Inbound Traffic\n(CIDR / SG source)"] -->|"allowed ports"| INGRESS
    INGRESS --> EC2
    EC2 --> EGRESS
    EGRESS --> INTERNET["Outbound Traffic"]

    style VPC fill:#FF9900,color:#fff,stroke:#FF9900
    style SG fill:#232F3E,color:#fff,stroke:#232F3E
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
