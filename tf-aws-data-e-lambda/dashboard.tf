# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_cloudwatch_dashboard ? 1 : 0

  dashboard_name = coalesce(var.dashboard_name, "${local.name}-lambda-dashboard")

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "## Lambda: **${local.name}**\nRegion: `${data.aws_region.current.name}` | Environment: `${var.environment}` | Runtime: `${var.runtime}` | Memory: `${var.memory_size} MB`"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          title   = "Invocations & Errors"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.this.function_name, { stat = "Sum", color = "#2ca02c", label = "Invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.this.function_name, { stat = "Sum", color = "#d62728", label = "Errors" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          title = "Duration (ms)"
          view  = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.this.function_name, { stat = "Average", label = "Avg" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "Maximum", label = "Max" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          title = "Throttles & Concurrency"
          view  = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Throttles", "FunctionName", aws_lambda_function.this.function_name, { stat = "Sum", color = "#ff7f0e", label = "Throttles" }],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", aws_lambda_function.this.function_name, { stat = "Maximum", color = "#1f77b4", label = "Concurrent" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title = "Cold Starts (Init Duration)"
          view  = "timeSeries"
          metrics = [
            ["AWS/Lambda", "InitDuration", "FunctionName", aws_lambda_function.this.function_name, { stat = "Average", label = "Avg Init" }],
            ["...", { stat = "Maximum", label = "Max Init" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Recent Errors"
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.this.name}' | filter @message like /(?i)error|exception/ | sort @timestamp desc | limit 20"
          region = data.aws_region.current.name
        }
      }
    ]
  })
}
