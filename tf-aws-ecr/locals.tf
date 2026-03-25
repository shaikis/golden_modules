locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-ecr"
    },
    var.tags
  )

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Cross-account principals from var + current account always included
  all_pull_principals = concat(
    [for a in var.cross_account_ids : "arn:aws:iam::${a}:root"],
    var.additional_pull_principals
  )

  default_lifecycle_policy = jsonencode({
    rules = concat(
      # Keep N tagged images matching prefixes
      [for idx, prefix in var.lifecycle_tag_prefixes : {
        rulePriority = idx + 1
        description  = "Keep ${var.tagged_image_count} images tagged with '${prefix}*'"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = [prefix]
          countType     = "imageCountMoreThan"
          countNumber   = var.tagged_image_count
        }
        action = { type = "expire" }
      }],
      [{
        rulePriority = length(var.lifecycle_tag_prefixes) + 1
        description  = "Expire untagged images > ${var.untagged_image_count}"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.untagged_image_count
        }
        action = { type = "expire" }
      }]
    )
  })

  lifecycle_policy_json = coalesce(var.lifecycle_policy, local.default_lifecycle_policy)
}
