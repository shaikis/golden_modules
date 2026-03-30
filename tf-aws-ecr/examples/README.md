# tf-aws-ecr Examples

Runnable examples for the [`tf-aws-ecr`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | One or more ECR repositories with KMS encryption (via tf-aws-kms), configurable push principal ARNs, and optional cross-account access |

## Architecture

```mermaid
graph TB
    subgraph KMS["AWS KMS (tf-aws-kms)"]
        KMSKey["KMS Key\n(ECR encryption)"]
    end

    subgraph ECR["Amazon ECR"]
        Repo1["Repository 1"]
        Repo2["Repository N"]
    end

    subgraph Access
        PushPrincipals["Push Principals\n(CI/CD roles, users)"]
        CrossAccount["Cross-Account IDs\n(pull access)"]
    end

    KMSKey --> Repo1
    KMSKey --> Repo2

    PushPrincipals -- "push/pull" --> Repo1
    PushPrincipals -- "push/pull" --> Repo2
    CrossAccount -- "pull" --> Repo1
    CrossAccount -- "pull" --> Repo2

    Output["repository_urls"]
    Repo1 --> Output
    Repo2 --> Output
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
