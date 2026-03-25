# ---------------------------------------------------------------------------
# Aurora Global Cluster (optional)
# ---------------------------------------------------------------------------
resource "aws_rds_global_cluster" "this" {
  count = var.create_global_cluster ? 1 : 0

  global_cluster_identifier = "${local.name}-global"
  engine                    = var.global_cluster_engine != null ? var.global_cluster_engine : var.engine
  engine_version            = var.global_cluster_engine_version != null ? var.global_cluster_engine_version : var.engine_version
  database_name             = var.database_name
  storage_encrypted         = var.storage_encrypted
  deletion_protection       = var.deletion_protection

  lifecycle { prevent_destroy = true }
}

# ---------------------------------------------------------------------------
# Aurora Cluster
# ---------------------------------------------------------------------------
resource "aws_rds_cluster" "this" {
  cluster_identifier = local.name

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = var.engine_mode

  # Global cluster association
  global_cluster_identifier = var.create_global_cluster ? aws_rds_global_cluster.this[0].id : var.global_cluster_identifier
  source_region             = var.global_cluster_identifier != null ? var.source_region : null

  # Serverless v2
  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.is_serverless_v2 ? var.serverlessv2_scaling : []
    content {
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
    }
  }

  # Database
  database_name                 = var.database_name
  master_username               = var.global_cluster_identifier != null ? null : var.master_username
  master_password               = var.manage_master_user_password || var.global_cluster_identifier != null ? null : var.master_password
  manage_master_user_password   = var.global_cluster_identifier != null ? null : var.manage_master_user_password
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  port                          = var.port

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  availability_zones     = length(var.availability_zones) > 0 ? var.availability_zones : null
  network_type           = var.network_type

  # Storage
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # Backup
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${local.name}"
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot
  backtrack_window             = var.engine == "aurora-mysql" ? var.backtrack_window : null

  # Protection
  deletion_protection = var.deletion_protection
  apply_immediately   = var.apply_immediately

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Parameters
  db_cluster_parameter_group_name = var.create_cluster_parameter_group ? aws_rds_cluster_parameter_group.this[0].name : var.cluster_parameter_group_name

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      master_password,
      global_cluster_identifier,
      availability_zones,
      tags["CreatedDate"],
    ]
  }
}
