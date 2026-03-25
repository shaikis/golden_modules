# ── IAM Execution Role ────────────────────────────────────────────────────────
# BYO pattern:
#   var.role_arn provided        → use it, skip creation
#   var.role_arn = null (default) → create new role (when create_role = true)
resource "aws_iam_role" "lambda" {
  count = var.create_role && var.role_arn == null ? 1 : 0

  name = "${local.name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  for_each = var.create_role && var.role_arn == null ? toset(local.all_managed_policies) : toset([])

  role       = aws_iam_role.lambda[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.create_role && var.role_arn == null ? var.inline_policies : {}

  name   = each.key
  role   = aws_iam_role.lambda[0].id
  policy = each.value
}

# Auto-attach EFS permissions when EFS mount is configured
resource "aws_iam_role_policy" "efs" {
  count = var.create_role && var.role_arn == null && local.has_efs ? 1 : 0

  name = "${local.name}-efs-access"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      Resource = var.efs_access_point_arn
    }]
  })
}
