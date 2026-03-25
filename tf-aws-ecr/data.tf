data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
