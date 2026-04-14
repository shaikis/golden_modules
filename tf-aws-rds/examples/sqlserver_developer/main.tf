terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "rds" {
  source = "../../"

  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  engine         = "sqlserver-dev-ee"
  engine_version = var.sqlserver_developer_custom_engine_version_name
  instance_class = var.instance_class
  license_model  = "bring-your-own-license"
  timezone       = var.timezone

  create_sqlserver_developer_custom_engine_version      = true
  sqlserver_developer_custom_engine_version_name        = var.sqlserver_developer_custom_engine_version_name
  sqlserver_developer_media_bucket_name                 = var.sqlserver_developer_media_bucket_name
  sqlserver_developer_media_bucket_prefix               = var.sqlserver_developer_media_bucket_prefix
  sqlserver_developer_media_files                       = var.sqlserver_developer_media_files
  sqlserver_developer_custom_engine_version_description = var.sqlserver_developer_custom_engine_version_description

  db_name  = null
  username = var.username
  port     = 1433

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = false
  publicly_accessible    = false

  backup_retention_period          = var.backup_retention_period
  backup_window                    = var.backup_window
  maintenance_window               = var.maintenance_window
  skip_final_snapshot              = var.skip_final_snapshot
  final_snapshot_identifier_prefix = var.final_snapshot_identifier_prefix
  copy_tags_to_snapshot            = true
  delete_automated_backups         = false
  deletion_protection              = var.deletion_protection

  monitoring_interval             = var.monitoring_interval
  create_monitoring_role          = var.monitoring_interval > 0
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  create_parameter_group = var.create_parameter_group
  parameter_group_family = var.parameter_group_family
  parameters             = var.parameters
}
