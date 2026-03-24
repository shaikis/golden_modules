data "aws_partition" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  name = "${local.name}-aurora-monitoring"

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
# Cluster Parameter Group
# ---------------------------------------------------------------------------
resource "aws_rds_cluster_parameter_group" "this" {
  count = var.create_cluster_parameter_group ? 1 : 0

  name        = "${local.name}-cpg"
  family      = var.cluster_parameter_group_family
  description = "Aurora cluster parameter group for ${local.name}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle { create_before_destroy = true }
}

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

# ---------------------------------------------------------------------------
# Cluster Instances
# ---------------------------------------------------------------------------
resource "aws_rds_cluster_instance" "this" {
  for_each = var.cluster_instances

  identifier         = "${local.name}-${each.key}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = coalesce(each.value.instance_class, var.instance_class)
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  db_subnet_group_name         = var.db_subnet_group_name
  publicly_accessible          = each.value.publicly_accessible
  availability_zone            = each.value.availability_zone
  auto_minor_version_upgrade   = each.value.auto_minor_version_upgrade
  promotion_tier               = each.value.promotion_tier
  preferred_maintenance_window = each.value.preferred_maintenance_window

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? try(aws_iam_role.monitoring[0].arn, var.monitoring_role_arn) : null

  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = each.value.performance_insights_enabled ? var.performance_insights_retention_period : null

  db_parameter_group_name = var.instance_parameter_group_name

  apply_immediately = var.apply_immediately

  tags = merge(local.tags, { InstanceRole = each.value.promotion_tier == 0 ? "writer" : "reader" })

  lifecycle {
    prevent_destroy       = true
    ignore_changes        = [engine_version, tags["CreatedDate"]]
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling for Read Replicas
# ---------------------------------------------------------------------------
resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.this.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity

  depends_on = [aws_rds_cluster_instance.this]
}

resource "aws_appautoscaling_policy" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = "${local.name}-aurora-autoscaling"
  policy_type        = var.autoscaling_policy_type
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value       = var.autoscaling_target_cpu
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}
