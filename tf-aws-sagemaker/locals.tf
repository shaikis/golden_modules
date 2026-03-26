locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""

  tags = merge(
    {
      ManagedBy = "terraform"
      Module    = "tf-aws-sagemaker"
    },
    var.tags
  )

  role_arn = var.create_iam_role ? aws_iam_role.sagemaker[0].arn : var.role_arn

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition
}
