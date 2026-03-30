# tf-aws-sqs Examples

Runnable examples for the [`tf-aws-sqs`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — creates an SQS queue with standard tagging (name, environment, project, owner, cost center) |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-sqs basic example"
        SQS["SQS Queue"]
    end

    PUB["Producers\n(Lambda / SNS / S3 / etc.)"] -->|send message| SQS
    SQS -->|poll messages| CON["Consumers\n(Lambda / EC2 / ECS)"]
    SQS -->|failed messages| DLQ["Dead-Letter Queue\n(optional)"]
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
