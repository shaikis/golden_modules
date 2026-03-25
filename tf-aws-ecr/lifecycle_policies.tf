# ===========================================================================
# LIFECYCLE POLICY (applied to each repo)
# ===========================================================================
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.repositories

  repository = aws_ecr_repository.this[each.key].name
  policy     = local.lifecycle_policy_json
}
