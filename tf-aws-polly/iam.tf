# ── IAM Role ───────────────────────────────────────────────────
# Only created when create_iam_role = true (default).
# Set create_iam_role = false and supply role_arn to bring your own role.

resource "aws_iam_role" "polly" {
  count = var.create_iam_role ? 1 : 0

  name        = "${local.name_prefix}polly-role"
  description = "IAM role for Amazon Polly access (tf-aws-polly module)"

  assume_role_policy = data.aws_iam_policy_document.polly_assume_role[0].json

  tags = local.tags
}

resource "aws_iam_role_policy" "polly_inline" {
  count = var.create_iam_role ? 1 : 0

  name   = "${local.name_prefix}polly-inline-policy"
  role   = aws_iam_role.polly[0].id
  policy = data.aws_iam_policy_document.polly_inline[0].json
}
