# tf-aws-bedrock Examples

Runnable examples for the [`tf-aws-bedrock`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Full configuration with KMS encryption, model invocation logging to S3, guardrails, knowledge bases backed by OpenSearch Serverless, and agents with action groups |

## Architecture

```mermaid
graph TB
    subgraph Bedrock["Amazon Bedrock"]
        Agents["Bedrock Agents"]
        KB["Knowledge Bases"]
        Guardrails["Guardrails"]
        Logging["Model Invocation Logging"]
    end

    KMS["AWS KMS Key"] -->|encrypts| Agents
    KMS -->|encrypts| KB
    KMS -->|encrypts| Guardrails

    Agents -->|queries| KB
    Agents -->|enforced by| Guardrails
    Agents -->|invokes| Lambda["Lambda<br/>(action group handler)"]
    Lambda -->|API schema| S3_Schema["S3 Bucket<br/>(API schema)"]

    KB -->|vector store| OSS["OpenSearch Serverless<br/>(vector index)"]
    KB -->|data source| S3_Data["S3 Bucket<br/>(knowledge base data)"]

    Logging -->|invocation logs| S3_Logs["S3 Bucket<br/>(invocation logs)"]

    IAM["IAM Role<br/>(Bedrock service)"] --> KB
    IAM --> Agents
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
