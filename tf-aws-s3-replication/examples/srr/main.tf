provider "aws" {
  region = var.aws_region
}

module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.environment
  tags        = var.tags
  keys = {
    s3 = {
      description = "S3 replication example key"
    }
  }
}

module "s3_with_srr" {
  source             = "../../"
  source_bucket_name = var.source_bucket_name
  source_region      = var.source_region
  environment        = var.environment
  project            = var.project
  source_kms_key_id  = module.kms.key_arns["s3"]

  enable_srr        = var.enable_srr
  srr_kms_key_id    = module.kms.key_arns["s3"]
  srr_bucket_name   = var.srr_bucket_name
  srr_storage_class = var.srr_storage_class

  enable_aws_backup     = var.enable_aws_backup
  backup_retention_days = var.backup_retention_days
  backup_kms_key_arn    = module.kms.key_arns["s3"]

  source_lifecycle_rules = var.source_lifecycle_rules
}
