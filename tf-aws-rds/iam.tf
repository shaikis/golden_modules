# ---------------------------------------------------------------------------
# Active Directory Domain Join IAM Role
# (SQL Server Windows Authentication — AWS Managed Microsoft AD)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "domain" {
  count = var.create_domain_iam_role && (var.domain != null || var.domain_fqdn != null) ? 1 : 0

  name = "${local.name}-rds-domain-join"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  # Grants RDS permission to:
  #   - ds:DescribeDirectories / ds:AuthorizeApplication / ds:UnauthorizeApplication
  #     (required for AWS Managed Microsoft AD join)
  #   - secretsmanager:GetSecretValue
  #     (required for self-managed AD — reads the domain-join service account)
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"]

  tags = local.tags
}

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
