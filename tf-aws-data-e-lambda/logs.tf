# ── CloudWatch Log Group ──────────────────────────────────────────────────────
# Created before the function so logs are retained even if function is deleted
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = local.tags
}
