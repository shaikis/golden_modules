# ===========================================================================
# ECR REPOSITORIES
# ===========================================================================
resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = "${local.name}/${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(local.tags, each.value.additional_tags)

  lifecycle {
    prevent_destroy = true
  }
}

# ===========================================================================
# LIFECYCLE POLICY (applied to each repo)
# ===========================================================================
locals {
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

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.repositories

  repository = aws_ecr_repository.this[each.key].name
  policy     = local.lifecycle_policy_json
}

# ===========================================================================
# REPOSITORY POLICY (cross-account pull + push principals)
# ===========================================================================
data "aws_iam_policy_document" "ecr_policy" {
  for_each = var.repositories

  # Pull access
  dynamic "statement" {
    for_each = length(local.all_pull_principals) > 0 ? [1] : []
    content {
      sid    = "CrossAccountPull"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = local.all_pull_principals
      }
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
      ]
    }
  }

  # Push access
  dynamic "statement" {
    for_each = length(var.push_principal_arns) > 0 ? [1] : []
    content {
      sid    = "CICDPush"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.push_principal_arns
      }
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
      ]
    }
  }

  # Deny unencrypted push
  statement {
    sid    = "DenyUnencryptedPush"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["ecr:PutImage"]
    condition {
      test     = "StringNotEquals"
      variable = "ecr:ResourceTag/Environment"
      values   = [var.environment]
    }
  }
}

resource "aws_ecr_repository_policy" "this" {
  for_each = {
    for k, v in var.repositories : k => v
    if length(local.all_pull_principals) > 0 || length(var.push_principal_arns) > 0
  }

  repository = aws_ecr_repository.this[each.key].name
  policy     = data.aws_iam_policy_document.ecr_policy[each.key].json
}

# ===========================================================================
# REPLICATION CONFIGURATION (registry-level)
# ===========================================================================
resource "aws_ecr_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replication_destinations
        content {
          region      = destination.value.region
          registry_id = destination.value.registry_id
        }
      }

      dynamic "repository_filter" {
        for_each = var.replication_repository_filters
        content {
          filter      = repository_filter.value
          filter_type = "PREFIX_MATCH"
        }
      }
    }
  }
}

# ===========================================================================
# PULL-THROUGH CACHE RULES
# ===========================================================================
resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = var.pull_through_cache_rules

  ecr_repository_prefix = each.key
  upstream_registry_url = each.value.upstream_registry_url
  credential_arn        = each.value.credential_arn
}
