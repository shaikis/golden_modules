# Multi-region setup with SRR + CRR + AWS Backup + Object Lock
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr_west"
  region = var.dr_west_region
}

provider "aws" {
  alias  = "dr_eu"
  region = var.dr_eu_region
}

# KMS keys in each region
module "kms_primary" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.environment
  tags        = var.tags
  keys = {
    s3 = {
      description = "S3 replication primary key"
    }
  }
  providers   = { aws = aws.primary }
}

module "kms_dr_west" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.environment
  tags        = var.tags
  keys = {
    s3 = {
      description = "S3 replication DR west key"
    }
  }
  providers   = { aws = aws.dr_west }
}

module "kms_dr_eu" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.environment
  tags        = var.tags
  keys = {
    s3 = {
      description = "S3 replication DR EU key"
    }
  }
  providers   = { aws = aws.dr_eu }
}

# Pre-create DR destination buckets (versioning required for CRR destination)
module "s3_dr_west" {
  source             = "../../../tf-aws-s3"
  providers          = { aws = aws.dr_west }
  bucket_name        = var.dr_west_bucket_name
  kms_master_key_id  = module.kms_dr_west.key_arns["s3"]
  versioning_enabled = true
}

module "s3_dr_eu" {
  source             = "../../../tf-aws-s3"
  providers          = { aws = aws.dr_eu }
  bucket_name        = var.dr_eu_bucket_name
  kms_master_key_id  = module.kms_dr_eu.key_arns["s3"]
  versioning_enabled = true
}

# Source bucket with ALL backup strategies enabled
module "s3_platform" {
  source             = "../../"
  providers          = { aws = aws.primary }
  source_bucket_name = var.source_bucket_name
  source_region      = var.source_region
  environment        = var.environment
  project            = var.project
  owner              = var.owner
  cost_center        = var.cost_center
  source_kms_key_id  = module.kms_primary.key_arns["s3"]

  # SRR — same-region backup
  enable_srr        = var.enable_srr
  srr_bucket_name   = var.srr_bucket_name
  srr_kms_key_id    = module.kms_primary.key_arns["s3"]
  srr_storage_class = var.srr_storage_class

  # CRR — cross-region replication
  enable_crr = var.enable_crr
  crr_destinations = {
    dr_us_west = {
      bucket_arn    = module.s3_dr_west.bucket_arn
      region        = var.dr_west_region
      kms_key_id    = module.kms_dr_west.key_arns["s3"]
      storage_class = "STANDARD_IA"
      delete_marker_replication = true
    }
    dr_eu_west = {
      bucket_arn    = module.s3_dr_eu.bucket_arn
      region        = var.dr_eu_region
      kms_key_id    = module.kms_dr_eu.key_arns["s3"]
      storage_class = "GLACIER"
      prefix_filter = "critical/"  # only replicate this prefix
    }
  }

  # AWS Backup — scheduled point-in-time recovery
  enable_aws_backup     = var.enable_aws_backup
  backup_vault_name     = var.backup_vault_name
  backup_schedule       = var.backup_schedule
  backup_retention_days = var.backup_retention_days
  backup_kms_key_arn    = module.kms_primary.key_arns["s3"]

  # Lifecycle — transition old objects
  source_lifecycle_rules = var.source_lifecycle_rules

  tags = var.tags
}
