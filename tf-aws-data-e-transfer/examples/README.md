# tf-aws-data-e-transfer Examples

Runnable examples for the [`tf-aws-data-e-transfer`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — public-facing SFTP server with service-managed SSH key authentication and an S3 landing bucket |
| [complete](complete/) | Full configuration with VPC SFTP server, per-partner scoped home directories, managed post-upload workflows, CloudWatch logging, WAF IP allowlist, KMS-encrypted S3 backend, and downstream Lambda trigger |

## Architecture

```mermaid
graph LR
    subgraph Sources["External Clients"]
        SFTP["SFTP Clients\n(partners · vendors)"]
        FTPS["FTPS / AS2\n(legacy · EDI)"]
    end
    subgraph Processing["AWS Transfer Family"]
        SRV["Transfer Server\n(VPC endpoint)"]
        USERS["User Mappings\n(scoped home dirs)"]
        WFLOW["Managed Workflows\n(copy · tag · Lambda)"]
    end
    subgraph Destinations["Storage & Downstream"]
        S3["S3 Landing Zone\n(partitioned by partner)"]
        LAMBDA["Lambda\n(post-transfer trigger)"]
        GLUE["Glue ETL Job"]
    end
    SFTP --> SRV
    FTPS --> SRV
    SRV --> USERS
    WFLOW --> SRV
    USERS --> S3
    S3 --> LAMBDA --> GLUE
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply -var-file="dev.tfvars"
```
