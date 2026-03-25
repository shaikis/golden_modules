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
