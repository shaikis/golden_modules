# tf-aws-sns Examples

Runnable examples for the [`tf-aws-sns`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — creates an SNS topic with standard tagging (name, environment, project, owner, cost center) |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-sns basic example"
        SNS["SNS Topic"]
    end

    PUB["Publishers\n(Lambda / CloudWatch / S3 / etc.)"] -->|publish message| SNS
    SNS -->|fan-out| SUB1["Subscriber\n(SQS Queue)"]
    SNS -->|fan-out| SUB2["Subscriber\n(Lambda)"]
    SNS -->|fan-out| SUB3["Subscriber\n(Email / HTTP)"]
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
