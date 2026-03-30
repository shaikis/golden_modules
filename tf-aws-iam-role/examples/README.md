# tf-aws-iam-role Examples

Runnable examples for the [`tf-aws-iam-role`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal EC2 service role — trusted service principal, optional instance profile, and managed policy attachments |
| [complete](complete/) | Full configuration with tagging, assume-role conditions, custom session duration, and inline policies for S3 and KMS access |

## Architecture

```mermaid
graph TB
    subgraph Basic["basic — EC2 Service Role"]
        EC2SVC["ec2.amazonaws.com\n(trusted principal)"]
        ROLE_B["IAM Role"]
        IP["Instance Profile"]
        MP["Managed Policy ARNs"]

        EC2SVC -->|"sts:AssumeRole"| ROLE_B
        ROLE_B --> IP
        ROLE_B --> MP
    end

    subgraph Complete["complete — Full Configuration"]
        SVC["Trusted Service\nPrincipal"]
        COND["Assume-Role\nConditions"]
        ROLE_C["IAM Role"]
        INL_S3["Inline Policy\ns3:GetObject / PutObject"]
        INL_KMS["Inline Policy\nkms:Decrypt / GenerateDataKey"]
        MANAGED["Managed Policy\nAttachments"]

        SVC -->|"sts:AssumeRole"| ROLE_C
        COND -->|"restrict"| ROLE_C
        ROLE_C --> INL_S3
        ROLE_C --> INL_KMS
        ROLE_C --> MANAGED
    end

    style Basic fill:#FF9900,color:#fff,stroke:#FF9900
    style Complete fill:#232F3E,color:#fff,stroke:#232F3E
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
