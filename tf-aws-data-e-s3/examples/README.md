# tf-aws-data-e-s3 Examples

Runnable examples for the [`tf-aws-data-e-s3`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal S3 bucket with secure defaults — KMS encryption, versioning, and public access block enabled out of the box |
| [complete](complete/) | Full production setup: KMS encryption, access logging to a separate log bucket, lifecycle rules, Intelligent-Tiering, deny-HTTP and require-TLS-1.2 bucket policies |

## Architecture

```mermaid
graph TD
    subgraph Basic["basic/ — Secure Defaults"]
        B_APP["Application / User"] -->|HTTPS only| B_BUCKET["S3 Bucket\n(KMS-encrypted, versioned)"]
        B_BUCKET --> B_PAB["Public Access Block\n(all 4 settings)"]
        B_BUCKET --> B_KMS["KMS Key\n(SSE-KMS + bucket key)"]
    end

    subgraph Complete["complete/ — Full Production"]
        APP["Application / User"] -->|HTTPS only| BUCKET["S3 Bucket\n(KMS, versioned)"]

        subgraph Security["Security"]
            DENY_HTTP["Deny HTTP policy"]
            REQ_TLS["Require TLS 1.2 policy"]
            KMS_KEY["Customer KMS Key\n(tf-aws-kms module)"]
        end

        subgraph DataMgmt["Data Management"]
            LIFECYCLE["Lifecycle Rules\n(Standard → IA → Glacier → expire)"]
            INTELL["Intelligent-Tiering\n(auto cost optimisation)"]
            VERSIONS["Versioning + noncurrent expiry"]
        end

        subgraph Observability["Observability"]
            LOG_BUCKET["Log Bucket\n(access logs)"]
        end

        subgraph Events["Event Notifications (opt-in)"]
            LAMBDA["Lambda Function"]
            SQS["SQS Queue"]
            SNS_T["SNS Topic"]
        end

        BUCKET --> DENY_HTTP
        BUCKET --> REQ_TLS
        KMS_KEY --> BUCKET
        BUCKET --> LIFECYCLE
        BUCKET --> INTELL
        BUCKET --> VERSIONS
        BUCKET -->|access logs| LOG_BUCKET
        BUCKET -->|ObjectCreated| LAMBDA
        BUCKET -->|ObjectCreated| SQS
        BUCKET -->|ObjectRemoved| SNS_T
    end
```

## Quick Start

```bash
# Basic — minimal secure bucket
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"

# Complete — full production configuration
cd complete/
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## Feature Comparison

| Feature | basic | complete |
|---------|-------|----------|
| KMS encryption | AWS-managed key | Customer-managed key (tf-aws-kms) |
| Versioning | Enabled | Enabled + noncurrent expiry |
| Public access block | All 4 settings | All 4 settings |
| Deny HTTP policy | Yes | Yes |
| Require TLS 1.2 policy | No | Yes |
| Access logging | No | Yes (dedicated log bucket) |
| Lifecycle rules | No | Yes (IA → Glacier → expire) |
| Intelligent-Tiering | No | Yes |
| Event notifications | No | Configurable (Lambda / SQS / SNS) |
| Cross-region replication | No | Configurable |
