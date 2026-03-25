# ── EventBridge Scheduler ─────────────────────────────────────────────────────
# Auto-create a minimal scheduler IAM role when schedules are defined
resource "aws_iam_role" "scheduler" {
  count = length(var.schedules) > 0 && var.scheduler_role_arn == null ? 1 : 0

  name = "${local.name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  count = length(var.schedules) > 0 && var.scheduler_role_arn == null ? 1 : 0

  name = "${local.name}-scheduler-invoke"
  role = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.this.arn,
        "${aws_lambda_function.this.arn}:*"
      ]
    }]
  })
}

resource "aws_scheduler_schedule" "this" {
  for_each = var.schedules

  name        = "${local.name}-${each.key}"
  description = each.value.description
  state       = each.value.state

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone

  flexible_time_window {
    mode                      = each.value.flexible_time_window_minutes > 0 ? "FLEXIBLE" : "OFF"
    maximum_window_in_minutes = each.value.flexible_time_window_minutes > 0 ? each.value.flexible_time_window_minutes : null
  }

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = local.effective_scheduler_role_arn
    input    = each.value.input

    dynamic "retry_policy" {
      for_each = each.value.retry_maximum_retry_attempts != null ? [1] : []
      content {
        maximum_event_age_in_seconds = each.value.retry_maximum_event_age_in_seconds
        maximum_retry_attempts       = each.value.retry_maximum_retry_attempts
      }
    }
  }
}
