locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""

  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "tf-aws-transcribe"
  })

  role_arn = var.create_iam_role ? aws_iam_role.transcribe[0].arn : var.role_arn
}
