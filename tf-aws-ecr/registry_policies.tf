# ===========================================================================
# REPOSITORY POLICY (cross-account pull + push principals)
# ===========================================================================
resource "aws_ecr_repository_policy" "this" {
  for_each = {
    for k, v in var.repositories : k => v
    if length(local.all_pull_principals) > 0 || length(var.push_principal_arns) > 0
  }

  repository = aws_ecr_repository.this[each.key].name
  policy     = data.aws_iam_policy_document.ecr_policy[each.key].json
}
