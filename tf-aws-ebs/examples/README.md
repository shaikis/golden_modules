# tf-aws-ebs Examples

Runnable examples for the [`tf-aws-ebs`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — creates EBS volumes with KMS encryption, optional volume attachments, and a DLM lifecycle policy for automated snapshots |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-ebs basic example"
        KMS["tf-aws-kms\n(KMS Key)"]
        EBS["tf-aws-ebs\n(EBS Volumes + Attachments)"]
        DLM["DLM Lifecycle Policy\n(Automated Snapshots)"]

        KMS -->|kms_key_arn| EBS
        EBS -->|encrypt volumes| DLM
    end

    EC2["EC2 Instance"] -->|volume attachment| EBS
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
