# ---------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  name = "${local.name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Custom Parameter Group
# ---------------------------------------------------------------------------
resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${local.name}-pg"
  family      = var.parameter_group_family
  description = "Parameter group for ${local.name}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier = local.name

  # Engine
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  license_model               = var.license_model
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  ca_cert_identifier          = var.ca_cert_identifier
  character_set_name          = var.character_set_name
  timezone                    = var.timezone
  network_type                = var.network_type

  # Database
  db_name                       = var.db_name
  username                      = var.replicate_source_db != null ? null : var.username
  password                      = var.manage_master_user_password || var.replicate_source_db != null ? null : var.password
  manage_master_user_password   = var.replicate_source_db != null ? null : var.manage_master_user_password
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  port                          = var.port

  # Replica
  replicate_source_db = var.replicate_source_db

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.multi_az ? null : var.availability_zone
  multi_az               = var.multi_az

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${local.name}"
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  delete_automated_backups  = var.delete_automated_backups

  # Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? try(aws_iam_role.monitoring[0].arn, var.monitoring_role_arn) : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports

  # Parameters
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.option_group_name

  tags = local.tags

  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = true
    # Ignore password changes (managed externally / by Secrets Manager)
    ignore_changes = [password, tags["CreatedDate"]]
  }
}
