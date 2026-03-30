# tf-aws-ec2 Examples

Runnable examples for the [`tf-aws-ec2`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — single EC2 instance with essential inputs only (instance type, subnet, key pair, monitoring toggle) |
| [complete](complete/) | Full configuration with KMS-encrypted EBS root volume, dedicated IAM instance role with SSM access, security group, EIP, Spot support, CPU options, and metadata options |

## Architecture

```mermaid
graph TB
    subgraph Complete["Complete Example"]
        KMS["KMS Key\n(EBS encryption)"]
        Role["IAM Role +\nInstance Profile\n(SSM access)"]
        SG["Security Group\n(SSH from 10/8, all egress)"]
        EC2["EC2 Instance"]
        EIP["Elastic IP\n(optional)"]
    end

    KMS -->|root_volume_kms_key_id| EC2
    Role -->|iam_instance_profile| EC2
    SG -->|vpc_security_group_ids| EC2
    EC2 -->|create_eip| EIP
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
