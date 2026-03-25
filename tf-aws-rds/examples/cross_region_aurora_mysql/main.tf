# ===========================================================================
# Aurora MySQL — Global Database Cross-Region Setup
# ─────────────────────────────────────────────────────────────────────────
# Aurora cross-region uses Global Database (different from standard RDS).
# One global cluster wraps a primary + optional secondary cluster.
#
# Choice-based toggles (set in tfvars):
#   create_secondary_region = true   → add a secondary Aurora cluster in DR
#
# Switch environment:
#   terraform apply -var-file="dev.tfvars"
#   terraform apply -var-file="staging.tfvars"
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

provider "aws" { alias = "primary"; region = var.primary_region }
provider "aws" { alias = "dr";      region = var.dr_region }

locals {
  name = "${var.project}-${var.environment}-${var.name}"
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Aurora Global Cluster
# ---------------------------------------------------------------------------
resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = "${local.name}-global"
  engine                    = "aurora-mysql"
  engine_version            = var.engine_version
  database_name             = var.db_name
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection

  lifecycle {
    ignore_changes = [engine_version]
  }
}

# ---------------------------------------------------------------------------
# Primary Aurora Cluster (primary region)
# ---------------------------------------------------------------------------
resource "aws_rds_cluster" "primary" {
  provider = aws.primary

  cluster_identifier        = "${local.name}-primary"
  engine                    = "aurora-mysql"
  engine_version            = var.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id

  database_name               = var.db_name
  master_username             = var.username
  manage_master_user_password = true

  # Attach multiple security groups via the list variable
  db_subnet_group_name   = var.primary_subnet_group_name
  vpc_security_group_ids = var.primary_security_group_ids

  kms_key_id = var.primary_kms_key_arn

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${local.name}-primary-final"
  copy_tags_to_snapshot        = true
  deletion_protection          = var.deletion_protection

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(local.common_tags, { Name = "${local.name}-primary" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [replication_source_identifier, engine_version]
  }
}

# Primary cluster instances (count-based for easy scale up/down)
resource "aws_rds_cluster_instance" "primary" {
  count    = var.primary_instance_count
  provider = aws.primary

  identifier         = "${local.name}-primary-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = var.primary_instance_class
  engine             = aws_rds_cluster.primary.engine
  engine_version     = aws_rds_cluster.primary.engine_version

  publicly_accessible          = false
  monitoring_interval          = var.monitoring_interval
  performance_insights_enabled = var.performance_insights_enabled
  auto_minor_version_upgrade   = true

  tags = merge(local.common_tags, { Name = "${local.name}-primary-${count.index + 1}" })
}

# ---------------------------------------------------------------------------
# Secondary Aurora Cluster — DR region (choice-based)
# NOTES:
#   - secondary_security_group_ids must contain SGs from the DR VPC
#     (security groups are VPC-specific and cannot be shared cross-region)
#   - dr_kms_key_arn is required when source is encrypted
#   - depends_on primary instances ensures primary is ready first
# ---------------------------------------------------------------------------
resource "aws_rds_cluster" "secondary" {
  count    = var.create_secondary_region ? 1 : 0
  provider = aws.dr

  cluster_identifier        = "${local.name}-secondary"
  engine                    = "aurora-mysql"
  engine_version            = var.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id

  # source_region needed for encrypted global clusters
  source_region = var.primary_region

  # Security groups for DR VPC — MUST be SGs from the DR VPC, not primary VPC
  db_subnet_group_name   = var.dr_subnet_group_name
  vpc_security_group_ids = var.dr_security_group_ids

  kms_key_id = var.dr_kms_key_arn

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  tags = merge(local.common_tags, { Name = "${local.name}-secondary" })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [replication_source_identifier, engine_version]
  }

  depends_on = [aws_rds_cluster_instance.primary]
}

# Secondary cluster instances
resource "aws_rds_cluster_instance" "secondary" {
  count    = var.create_secondary_region ? var.dr_instance_count : 0
  provider = aws.dr

  identifier         = "${local.name}-secondary-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.secondary[0].id
  instance_class     = var.dr_instance_class
  engine             = "aurora-mysql"
  engine_version     = var.engine_version

  publicly_accessible          = false
  monitoring_interval          = var.monitoring_interval
  performance_insights_enabled = var.performance_insights_enabled
  auto_minor_version_upgrade   = true

  tags = merge(local.common_tags, { Name = "${local.name}-secondary-${count.index + 1}" })
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "global_cluster_id"          { value = aws_rds_global_cluster.this.id }
output "primary_cluster_id"         { value = aws_rds_cluster.primary.id }
output "primary_cluster_endpoint"   { value = aws_rds_cluster.primary.endpoint }
output "primary_reader_endpoint"    { value = aws_rds_cluster.primary.reader_endpoint }
output "primary_secret_arn"         { value = aws_rds_cluster.primary.master_user_secret[0].secret_arn }

output "secondary_cluster_id" {
  value = var.create_secondary_region ? aws_rds_cluster.secondary[0].id : null
}
output "secondary_cluster_endpoint" {
  value = var.create_secondary_region ? aws_rds_cluster.secondary[0].endpoint : null
}
output "secondary_reader_endpoint" {
  value = var.create_secondary_region ? aws_rds_cluster.secondary[0].reader_endpoint : null
}
