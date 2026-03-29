# tf-aws-secretsmanager

Terraform module for AWS Secrets Manager.

## Architecture

```mermaid
graph TB
    subgraph Core["Secrets Manager Secret"]
        style Core fill:#FF9900,color:#fff,stroke:#FF9900
        SEC["aws_secretsmanager_secret\n(prevent_destroy = true)"]
        SV["aws_secretsmanager_secret_version\n(ignore_changes on secret_string)"]
        SEC --> SV
    end

    subgraph Encryption["Encryption"]
        style Encryption fill:#232F3E,color:#fff,stroke:#232F3E
        KMS["KMS Customer Managed Key\n(kms_key_id)"]
    end

    subgraph Rotation["Automatic Rotation"]
        style Rotation fill:#1A9C3E,color:#fff,stroke:#1A9C3E
        ROT["Rotation Schedule\naws_secretsmanager_secret_rotation"]
        LMB["Rotation Lambda Function\n(SecretsManager triggers)"]
        ROT --> LMB
    end

    subgraph Replication["Multi-Region Replication"]
        style Replication fill:#8C4FFF,color:#fff,stroke:#8C4FFF
        REP1["Replica Secret\nRegion 2"]
        REP2["Replica Secret\nRegion 3"]
    end

    subgraph Policy["Access Control"]
        style Policy fill:#DD344C,color:#fff,stroke:#DD344C
        RP["Resource-Based Policy\naws_secretsmanager_secret_policy"]
        IAM["IAM Principal\n(cross-account / service)"]
        IAM -->|"secretsmanager:GetSecretValue"| RP
    end

    KMS -->|"encrypts"| SEC
    SEC --> ROT
    SEC -->|"replicates to"| REP1
    SEC -->|"replicates to"| REP2
    RP --> SEC
```

## Features

- KMS encryption (customer-managed)
- Automatic rotation via Lambda
- Multi-region replication
- Resource-based policy
- `prevent_destroy` lifecycle guard
- `ignore_changes` on secret value (value managed externally after initial creation)

## Security Controls

| Control | Default |
|---------|---------|
| KMS encryption | Optional (strongly recommended) |
| Recovery window | 30 days |
| `prevent_destroy` | `true` |
| Secret value ignored on re-apply | `ignore_changes = [secret_string]` |

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "secret" {
  source     = "git::https://github.com/your-org/tf-modules.git//tf-aws-secretsmanager?ref=v1.0.0"
  name       = "prod/app/database"
  kms_key_id = module.kms.key_arn
  environment = "prod"
}
```
