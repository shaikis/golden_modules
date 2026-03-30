# tf-aws-iam Examples

Runnable examples for the [`tf-aws-iam`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — provider and version constraints only, no IAM resources created |
| [complete](complete/) | Full configuration with service, cross-account, and federated roles, managed and inline policy attachments, customer-managed policies, and instance profiles |
| [data-platform](data-platform/) | Data lake pattern — S3 read/write roles with KMS, Glue Catalog, and CloudWatch Logs policies for an analytics platform |

## Architecture

```mermaid
graph TB
    subgraph Roles["IAM Roles"]
        SR["Service Role\n(Lambda / ECS / EC2)"]
        CA["Cross-Account Role\n(sts:AssumeRole)"]
        FED["Federated Role\n(OIDC / SAML)"]
        IP["Instance Profile\n(EC2 launch)"]
    end

    subgraph Policies["Policies"]
        MP["AWS Managed Policies"]
        CMP["Customer Managed\nPolicies"]
        INL["Inline Policies\n(role-scoped)"]
    end

    subgraph DataLake["Data Lake Policy Docs"]
        S3R["S3 Read Policy"]
        S3W["S3 Write Policy"]
        KP["KMS Policy"]
        GLP["Glue Catalog Policy"]
        CWP["CloudWatch Logs Policy"]
    end

    OIDC["OIDC Provider\n(EKS / GitHub Actions)"]
    EC2["EC2 Instance"]

    OIDC --> FED
    FED --> CMP
    SR --> MP
    SR --> INL
    CA --> CMP
    IP --> EC2
    SR --> IP
    CMP --> S3R
    CMP --> S3W
    CMP --> KP
    CMP --> GLP
    CMP --> CWP

    style Roles fill:#FF9900,color:#fff,stroke:#FF9900
    style Policies fill:#DD344C,color:#fff,stroke:#DD344C
    style DataLake fill:#1A9C3E,color:#fff,stroke:#1A9C3E
    style OIDC fill:#232F3E,color:#fff,stroke:#232F3E
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
