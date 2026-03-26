locals {
  # Prepend a hyphenated prefix when one is provided.
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""

  # Common tags merged onto every resource.
  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "tf-aws-rekognition"
    }
  )

  # Resolved IAM role ARN: auto-created or BYO.
  role_arn = var.create_iam_role ? aws_iam_role.rekognition[0].arn : var.role_arn

  # Shorthand account / region / partition from data sources.
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Stream processors that actually exist (used for alarm iteration).
  active_stream_processors = var.create_stream_processors ? var.stream_processors : {}
}
