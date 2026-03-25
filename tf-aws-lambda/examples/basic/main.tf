# =============================================================================
# Basic Lambda Example
# -----------------------------------------------------------------------------
# Simplest possible Lambda deployment:
#   - Python function from a local zip file
#   - No VPC  (public Lambda with internet access)
#   - Auto-created IAM role  (or pass role_arn to reuse an existing one)
#   - CloudWatch Logs  (always created)
#   - Optional alarms
#
# Usage:
#   terraform apply -var-file="dev.tfvars"
#   terraform apply -var-file="prod.tfvars"
# =============================================================================

provider "aws" {
  region = var.aws_region
}

module "lambda" {
  source = "../../"

  # ── Naming ───────────────────────────────────────────────────────────────────
  function_name = var.function_name
  name_prefix   = var.name_prefix
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  description   = var.description
  tags          = var.tags

  # ── IAM Role ─────────────────────────────────────────────────────────────────
  # Option A (default): module auto-creates a role
  #   create_role = true, role_arn = null
  # Option B: pass an existing role from the root module
  #   create_role = false, role_arn = "arn:aws:iam::123456789012:role/my-role"
  create_role = var.create_role
  role_arn    = var.role_arn

  # ── Runtime ───────────────────────────────────────────────────────────────────
  runtime     = var.runtime
  handler     = var.handler
  memory_size = var.memory_size
  timeout     = var.timeout

  # ── Code (local zip) ─────────────────────────────────────────────────────────
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  # ── Environment Variables ─────────────────────────────────────────────────────
  environment_variables = var.environment_variables

  # ── CloudWatch Logs ───────────────────────────────────────────────────────────
  log_retention_days = var.log_retention_days

  # ── Alarms ───────────────────────────────────────────────────────────────────
  create_cloudwatch_alarms = var.create_cloudwatch_alarms
  alarm_sns_topic_arn      = var.alarm_sns_topic_arn
  alarm_error_threshold    = var.alarm_error_threshold
}
