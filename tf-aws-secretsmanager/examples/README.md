# tf-aws-secretsmanager Examples

Runnable examples for the [`tf-aws-secretsmanager`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal secret creation with standard tagging — name, environment, project, owner, and cost centre metadata |

## Architecture

```mermaid
graph TB
    subgraph SecretsManager["AWS Secrets Manager"]
        SECRET["Secret\n(name + description)"]
        VER["Secret Version\n(initial value)"]
    end

    subgraph Tags["Resource Tags"]
        ENV["environment"]
        PROJ["project"]
        OWNER["owner"]
        CC["cost_center"]
    end

    CALLER["Terraform Caller\n(authenticated identity)"] -->|"secretsmanager:CreateSecret"| SECRET
    SECRET --> VER
    SECRET --> Tags

    style SecretsManager fill:#DD344C,color:#fff,stroke:#DD344C
    style Tags fill:#232F3E,color:#fff,stroke:#232F3E
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
