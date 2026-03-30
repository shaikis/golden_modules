# tf-aws-data-e-bedrock Examples

Runnable examples for the [`tf-aws-data-e-bedrock`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Full configuration with KMS encryption, model invocation logging to S3, content-safety guardrails, a RAG knowledge base backed by OpenSearch Serverless, and a Bedrock agent with action groups |

## Architecture

```mermaid
graph LR
    subgraph Sources["Data Ingestion"]
        S3["S3 Documents\n(PDFs · text)"]
    end
    subgraph Processing["Amazon Bedrock"]
        KB["Knowledge Base\n(RAG · embeddings)"]
        AGENT["Bedrock Agent\n(foundation model)"]
        GR["Guardrails\n(content safety · PII)"]
    end
    subgraph Destinations["Consumers & Logging"]
        LAMBDA["Lambda\n(action handler)"]
        LOG["S3 / CloudWatch\n(invocation logs)"]
    end
    Sources --> KB
    KB --> AGENT
    GR --> AGENT
    AGENT --> LAMBDA
    AGENT --> LOG
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
