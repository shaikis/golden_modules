# tf-aws-data-e-sagemaker Examples

Runnable examples for the [`tf-aws-data-e-sagemaker`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — single SageMaker Studio domain with IAM authentication deployed in a private VPC |
| [complete](complete/) | Full configuration with Studio domain, user profiles, training and batch-inference pipelines, A/B test endpoint (champion/challenger models with data capture), online and offline feature groups, and CloudWatch alarms |

## Architecture

```mermaid
graph LR
    subgraph Sources["Data & Models"]
        S3["S3 Data Buckets\n(training · batch input)"]
        FG["Feature Store\n(online · offline)"]
    end
    subgraph Processing["Amazon SageMaker"]
        STUDIO["Studio Domain\n(user profiles)"]
        PIPE["Pipelines\n(preprocess · train · transform)"]
        MODEL["Models\n(champion · challenger)"]
    end
    subgraph Destinations["Inference & Monitoring"]
        EP["Real-Time Endpoint\n(A/B test variants)"]
        BATCH["Batch Output\n(S3)"]
        CAP["Data Capture\n(S3)"]
    end
    S3 --> PIPE
    FG --> PIPE
    PIPE --> MODEL
    MODEL --> EP
    MODEL --> BATCH
    EP --> CAP
    STUDIO --> PIPE
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply -var-file="dev.tfvars"
```
