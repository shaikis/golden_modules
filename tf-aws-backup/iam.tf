############################################
# IAM ROLE
# create_iam_role = true  + iam_role_arn = null → module creates new role  (default)
# create_iam_role = false + iam_role_arn = ARN  → use existing role (BYO from another module)
############################################
resource "aws_iam_role" "backup" {
  # Only create when user has NOT supplied an existing role ARN
  count = var.create_iam_role && var.iam_role_arn == null ? 1 : 0

  name = coalesce(var.iam_role_name, "${local.name_prefix}-backup-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.create_iam_role && var.iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count      = var.create_iam_role && var.iam_role_arn == null ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy_attachment" "s3_backup" {
  count      = var.create_iam_role && var.iam_role_arn == null && var.enable_s3_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_iam_role_policy_attachment" "s3_restore" {
  count      = var.create_iam_role && var.iam_role_arn == null && var.enable_s3_backup ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
}
