# ===========================================================================
# RDS Cross-Region Setup
# ─────────────────────────────────────────────────────────────────────────
# This example shows two patterns (toggle in tfvars):
#   Pattern 1: automated_backup_replication = true
#              Copies automated backups from primary → DR region.
#              Used for: point-in-time recovery, compliance retention.
#
#   Pattern 2: create_cross_region_replica = true
#              Creates a live read replica in the DR region from primary.
#              Used for: DR failover, offloading reads across regions.
#
# Both patterns can run independently or together.
# Switch between environments by changing the tfvars file:
#   terraform apply -var-file="dev.tfvars"
#   terraform apply -var-file="prod.tfvars"
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

# Primary region provider (e.g. us-east-1)
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# DR / secondary region provider (e.g. us-west-2)
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# ---------------------------------------------------------------------------
# PRIMARY RDS Instance (primary region)
# ---------------------------------------------------------------------------
module "rds_primary" {
  source = "../../"

  providers = {
    aws = aws.primary
  }

  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database
  db_name  = var.db_name
  username = var.username
  port     = var.port

  # Credentials (Secrets Manager recommended)
  manage_master_user_password   = var.manage_master_user_password
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = true
  kms_key_id            = var.primary_kms_key_arn

  # Network
  db_subnet_group_name   = var.primary_subnet_group_name
  vpc_security_group_ids = var.primary_security_group_ids
  multi_az               = var.multi_az
  publicly_accessible    = false

  # Backup — must be >= 1 for automated backup replication to work
  backup_retention_period          = var.backup_retention_period
  backup_window                    = var.backup_window
  maintenance_window               = var.maintenance_window
  skip_final_snapshot              = var.skip_final_snapshot
  final_snapshot_identifier_prefix = var.final_snapshot_identifier_prefix
  copy_tags_to_snapshot            = true
  delete_automated_backups         = false

  # Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  monitoring_interval          = var.monitoring_interval
  create_monitoring_role       = var.monitoring_interval > 0 ? true : false
  performance_insights_enabled = var.performance_insights_enabled

  # Logging
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Parameter group
  create_parameter_group = var.create_parameter_group
  parameter_group_family = var.parameter_group_family
  parameters             = var.parameters
}

# ---------------------------------------------------------------------------
# Pattern 1: Automated Backup Replication (choice-based)
# ─────────────────────────────────────────────────────────────────────────
# Copies automated backups from primary region to DR region.
# Runs in the DESTINATION region (provider = aws.dr).
# Requires backup_retention_period >= 1 on the primary instance.
# ---------------------------------------------------------------------------
resource "aws_db_instance_automated_backups_replication" "this" {
  count = var.enable_automated_backup_replication ? 1 : 0

  provider = aws.dr

  source_db_instance_arn = module.rds_primary.db_instance_arn
  retention_period       = var.automated_backup_replication_retention_period
  kms_key_id             = var.automated_backup_replication_kms_key_arn
}

# ---------------------------------------------------------------------------
# Pattern 2: Cross-Region Read Replica (choice-based)
# ─────────────────────────────────────────────────────────────────────────
# Creates a live read replica in the DR region.
# Useful for regional DR failover and read offloading.
# ---------------------------------------------------------------------------
module "rds_replica" {
  count  = var.create_cross_region_replica ? 1 : 0
  source = "../../"

  providers = {
    aws = aws.dr
  }

  name        = "${var.name}-replica"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = merge(var.tags, { Role = "read-replica" })

  # Point to primary as the source — Terraform will use cross-region ARN
  replicate_source_db = module.rds_primary.db_instance_arn

  # Replica uses same instance class or a smaller one
  instance_class = var.replica_instance_class

  # Storage encryption with DR region KMS key
  storage_encrypted = true
  kms_key_id        = var.dr_kms_key_arn

  # Network in DR region
  db_subnet_group_name   = var.dr_subnet_group_name
  vpc_security_group_ids = var.dr_security_group_ids
  publicly_accessible    = false

  # Replica doesn't need backup configured (backups from primary are used)
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = var.deletion_protection

  # Monitoring
  monitoring_interval          = var.monitoring_interval
  create_monitoring_role       = var.monitoring_interval > 0 ? true : false
  performance_insights_enabled = var.performance_insights_enabled
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "primary_db_instance_id" { value = module.rds_primary.db_instance_id }
output "primary_db_instance_arn" { value = module.rds_primary.db_instance_arn }
output "primary_db_endpoint" { value = module.rds_primary.db_instance_endpoint }

output "automated_backup_replication_id" {
  description = "Backup replication resource ID (null if disabled)"
  value       = var.enable_automated_backup_replication ? aws_db_instance_automated_backups_replication.this[0].id : null
}

output "replica_db_instance_id" {
  description = "Cross-region replica instance ID (null if disabled)"
  value       = var.create_cross_region_replica ? module.rds_replica[0].db_instance_id : null
}

output "replica_db_endpoint" {
  description = "Cross-region replica endpoint (null if disabled)"
  value       = var.create_cross_region_replica ? module.rds_replica[0].db_instance_endpoint : null
}
