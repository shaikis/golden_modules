# tf-aws-fsx Examples

Runnable examples for the [`tf-aws-fsx`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Single-region deployment with KMS, FSx for Windows, and FSx for ONTAP |
| [ontap-cross-region-dr](ontap-cross-region-dr/) | Cross-region ONTAP disaster recovery with SnapMirror, AWS Backup, and Route 53 failover |

## Diagram Coverage

Each example has its own Mermaid architecture diagram:

- [complete](complete/)
- [ontap-cross-region-dr](ontap-cross-region-dr/)

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
