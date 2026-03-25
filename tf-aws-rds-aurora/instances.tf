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
