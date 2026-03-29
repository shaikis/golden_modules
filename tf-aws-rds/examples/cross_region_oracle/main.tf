# ===========================================================================
# RDS Oracle — Cross-Region Setup
# Supported: oracle-ee, oracle-ee-cdb, oracle-se2, oracle-se2-cdb
# Choice-based:
#   enable_automated_backup_replication = true  → backup copy to DR
#   create_cross_region_replica         = true  → live read replica in DR
#   license_model = "bring-your-own-license"    → BYOL (default)
#               or "license-included"           → LI (higher cost, included)
# ===========================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" { alias = "primary"; region = var.primary_region }
provider "aws" { alias = "dr";      region = var.dr_region }

module "rds_primary" {
  source    = "../../"
  providers = { aws = aws.primary }

  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  engine         = var.oracle_edition    # oracle-ee | oracle-ee-cdb | oracle-se2 | oracle-se2-cdb
  engine_version = var.engine_version
  instance_class = var.instance_class
  license_model  = var.license_model    # bring-your-own-license | license-included

  # Oracle does not use db_name at instance creation
  db_name            = null
  username           = var.username
  port               = 1521
  character_set_name = var.character_set_name

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.primary_kms_key_arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = true
  kms_key_id            = var.primary_kms_key_arn

  db_subnet_group_name   = var.primary_subnet_group_name
  vpc_security_group_ids = var.primary_security_group_ids
  multi_az               = var.multi_az
  publicly_accessible    = false

  backup_retention_period          = var.backup_retention_period
  backup_window                    = var.backup_window
  maintenance_window               = var.maintenance_window
  skip_final_snapshot              = var.skip_final_snapshot
  final_snapshot_identifier_prefix = var.final_snapshot_identifier_prefix
  copy_tags_to_snapshot            = true
  delete_automated_backups         = false
  deletion_protection              = var.deletion_protection

  monitoring_interval          = var.monitoring_interval
  create_monitoring_role       = var.monitoring_interval > 0 ? true : false
  performance_insights_enabled = var.performance_insights_enabled
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  create_parameter_group = var.create_parameter_group
  parameter_group_family = var.parameter_group_family
  parameters             = var.parameters

  # ── Oracle national character set ────────────────────────────────────────
  # AL16UTF16 (default) is required for Unicode data in NCHAR/NVARCHAR2/NCLOB
  # UTF8 is the alternative; cannot be changed after creation.
  nchar_character_set_name = var.nchar_character_set_name

  # ── Oracle Option Group ───────────────────────────────────────────────────
  # Common Oracle options:
  #   APEX                        — Oracle Application Express
  #   OEM / OEM_AGENT             — Oracle Enterprise Manager
  #   STATSPACK                   — Performance statistics (alternative to AWR)
  #   NATIVE_NETWORK_ENCRYPTION   — Encrypt Oracle Net traffic (no SSL cert needed)
  #   SSL                         — TLS encryption via Oracle Wallet
  #   S3_INTEGRATION              — Direct SELECT/INSERT from S3
  #   TIMEZONE_FILE_AUTOUPGRADE   — Auto-upgrade DST time zone data
  create_option_group               = var.create_option_group
  option_group_engine_name          = var.oracle_edition
  option_group_major_engine_version = var.option_group_major_engine_version
  options                           = var.options
}

# Pattern 1: Automated backup replication
resource "aws_db_instance_automated_backups_replication" "this" {
  count    = var.enable_automated_backup_replication ? 1 : 0
  provider = aws.dr

  source_db_instance_arn = module.rds_primary.db_instance_arn
  retention_period       = var.automated_backup_replication_retention_period
  kms_key_id             = var.automated_backup_replication_kms_key_arn
}

# Pattern 2: Cross-region read replica
module "rds_replica" {
  count     = var.create_cross_region_replica ? 1 : 0
  source    = "../../"
  providers = { aws = aws.dr }

  name        = "${var.name}-replica"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = merge(var.tags, { Role = "read-replica" })

  replicate_source_db    = module.rds_primary.db_instance_arn
  instance_class         = var.replica_instance_class
  license_model          = var.license_model
  storage_encrypted      = true
  kms_key_id             = var.dr_kms_key_arn
  db_subnet_group_name   = var.dr_subnet_group_name
  vpc_security_group_ids = var.dr_security_group_ids
  publicly_accessible    = false

  backup_retention_period      = 1
  skip_final_snapshot          = true
  deletion_protection          = var.deletion_protection
  monitoring_interval          = var.monitoring_interval
  create_monitoring_role       = var.monitoring_interval > 0 ? true : false
  performance_insights_enabled = var.performance_insights_enabled
}

output "primary_instance_id"   { value = module.rds_primary.db_instance_id }
output "primary_endpoint"      { value = module.rds_primary.db_instance_endpoint }
output "primary_secret_arn"    { value = module.rds_primary.db_master_user_secret_arn }
output "backup_replication_id" { value = var.enable_automated_backup_replication ? aws_db_instance_automated_backups_replication.this[0].id : null }
output "replica_instance_id"   { value = var.create_cross_region_replica ? module.rds_replica[0].db_instance_id : null }
output "replica_endpoint"      { value = var.create_cross_region_replica ? module.rds_replica[0].db_instance_endpoint : null }
