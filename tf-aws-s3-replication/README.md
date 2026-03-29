# tf-aws-s3-replication

Terraform module for S3 bucket with built-in backup strategies:
- **SRR** (Same-Region Replication) — backup copy in same region
- **CRR** (Cross-Region Replication) — one or more replica buckets in other regions
- **AWS Backup** — scheduled backup plan with configurable retention
- **Object Lock** — WORM immutable storage (GOVERNANCE or COMPLIANCE)

## Architecture

```mermaid
graph TB
    subgraph Source["Source Account / Region"]
        style Source fill:#232F3E,color:#fff,stroke:#232F3E
        SB["S3 Source Bucket\n(Versioning Enabled)"]
        OL["Object Lock\n(WORM - GOVERNANCE/COMPLIANCE)"]
        IAM["IAM Replication Role\naws_iam_role + Policy"]
        SB --> OL
        SB --> IAM
    end

    subgraph SRR["Same-Region Replication (SRR)"]
        style SRR fill:#FF9900,color:#fff,stroke:#FF9900
        SRR_B["SRR Replica Bucket\n(Same Region)"]
        SRR_KMS["KMS Key\n(srr_kms_key_id)"]
        SRR_B --> SRR_KMS
    end

    subgraph CRR["Cross-Region Replication (CRR)"]
        style CRR fill:#1A9C3E,color:#fff,stroke:#1A9C3E
        CRR1["CRR Replica Bucket\nus-west-2"]
        CRR2["CRR Replica Bucket\neu-west-1"]
        CRR_KMS["KMS Keys\n(per-destination)"]
        CRR1 --> CRR_KMS
        CRR2 --> CRR_KMS
    end

    subgraph Backup["AWS Backup"]
        style Backup fill:#8C4FFF,color:#fff,stroke:#8C4FFF
        BP["Backup Plan\n(Scheduled)"]
        BV["Backup Vault\n(Retention Policy)"]
        BP --> BV
    end

    IAM -->|"Replication Rule"| SRR_B
    IAM -->|"Replication Rules\n(for_each destinations)"| CRR1
    IAM -->|"Replication Rules\n(for_each destinations)"| CRR2
    SB -->|"enable_aws_backup = true"| BP
```

## Replication Modes

| Mode | Use Case | Config |
|------|----------|--------|
| SRR | Disaster recovery within same region | `enable_srr = true` |
| CRR | DR across regions, compliance | `enable_crr = true` + `crr_destinations` map |
| Both SRR + CRR | Maximum durability | Both enabled |
| AWS Backup | Point-in-time restore | `enable_aws_backup = true` |
| Object Lock (WORM) | Ransomware protection | `object_lock_enabled = true` |

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
# SRR (Same-Region Backup)
module "s3_backup" {
  source             = "git::https://github.com/your-org/tf-modules.git//tf-aws-s3-replication?ref=v1.0.0"
  source_bucket_name = "prod-app-data"
  source_region      = "us-east-1"
  environment        = "prod"
  source_kms_key_id  = module.kms.key_arn

  enable_srr     = true
  srr_kms_key_id = module.kms.key_arn
}

# CRR (Cross-Region Replication to DR region)
module "s3_crr" {
  source             = "git::https://github.com/your-org/tf-modules.git//tf-aws-s3-replication?ref=v1.0.0"
  source_bucket_name = "prod-app-data"
  source_region      = "us-east-1"
  environment        = "prod"

  enable_crr = true
  crr_destinations = {
    us_west_dr = {
      bucket_arn = "arn:aws:s3:::prod-app-data-dr-us-west-2"
      region     = "us-west-2"
      kms_key_id = "arn:aws:kms:us-west-2:123456789:key/abc..."
    }
    eu_west_dr = {
      bucket_arn = "arn:aws:s3:::prod-app-data-dr-eu-west-1"
      region     = "eu-west-1"
    }
  }
}
```

## CRR Destination Bucket Setup

Destination buckets for CRR must be created separately in each region using the `tf-aws-s3` module with provider aliases:

```hcl
provider "aws" { alias = "dr"; region = "us-west-2" }

module "s3_dr_bucket" {
  source    = "./tf-aws-s3"
  providers = { aws = aws.dr }

  bucket_name        = "prod-app-data-dr-us-west-2"
  kms_master_key_id  = module.kms_dr.key_arn
  versioning_enabled = true   # Required for CRR destination
}
```

## Examples

- [Basic SRR](examples/srr/)
- [Complete CRR + AWS Backup](examples/complete/)

