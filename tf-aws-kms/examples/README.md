# tf-aws-kms Examples

Runnable examples for the [`tf-aws-kms`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — provider and version constraints only, no KMS resources created |
| [complete](complete/) | Full configuration with key rotation, multi-region support, key administrators, key users, grants, and aliases |

## Architecture

```mermaid
graph TB
    subgraph KMS["AWS KMS"]
        KEY["Customer Managed Key\n(CMK)"]
        ALIAS["Key Alias\n(friendly name)"]
        GRANT["Key Grant\n(AutoScaling)"]
    end

    subgraph Principals["IAM Principals"]
        ADMIN["Key Administrator Role\n(manage key lifecycle)"]
        USER1["App Server Role\n(encrypt / decrypt)"]
        USER2["Lambda Exec Role\n(encrypt / decrypt)"]
        AS["AutoScaling Role\n(via grant)"]
    end

    ADMIN -->|"kms:Create*, kms:Delete*\nkms:Enable*, kms:Disable*"| KEY
    USER1 -->|"kms:Encrypt\nkms:Decrypt\nkms:GenerateDataKey"| KEY
    USER2 -->|"kms:Encrypt\nkms:Decrypt\nkms:GenerateDataKey"| KEY
    AS -->|"via Grant:\nEncrypt, Decrypt\nGenerateDataKey\nCreateGrant"| GRANT
    GRANT --> KEY
    KEY --> ALIAS

    style KMS fill:#FF9900,color:#fff,stroke:#FF9900
    style Principals fill:#232F3E,color:#fff,stroke:#232F3E
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
