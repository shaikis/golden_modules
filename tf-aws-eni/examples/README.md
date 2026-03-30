# tf-aws-eni Examples

Runnable examples for the [`tf-aws-eni`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — provision one or more Elastic Network Interfaces with optional EIP association using variable-driven network interface definitions |

## Architecture

```mermaid
graph TB
    subgraph VPC["VPC"]
        subgraph Subnet["Subnet(s)"]
            ENI1["ENI\nprivate IP\n(static or dynamic)"]
            ENI2["ENI\nprivate IP + EIP"]
            ENI3["ENI\nmultiple IPs"]
        end
    end

    EIP["Elastic IP (EIP)"]
    Instance["EC2 Instance\n(optional attachment)"]

    EIP --> ENI2
    Instance -->|"attachment"| ENI1

    ENI1 -->|"eni_ids output"| Output1["eni_ids"]
    ENI2 -->|"eni_private_ips output"| Output2["eni_private_ips"]
    ENI2 -->|"eip_public_ips output"| Output3["eip_public_ips"]
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
