# =============================================================================
# tf-aws-cloudwatch — CloudWatch Synthetics (Canary Monitoring)
#
# Continuously monitors public or internal HTTP endpoints from outside your
# infrastructure. Each canary:
#   1. Runs a Node.js script on AWS Lambda (managed by Synthetics runtime)
#   2. Makes HTTP GET requests to the specified endpoint on a schedule
#   3. Stores results (screenshots, HAR files) in S3
#   4. Emits SuccessPercent metric to CloudWatch
#   5. Triggers an alarm when the endpoint is unavailable or returns wrong status
#
# IAM role: auto-created if canary_execution_role_arn is null
# S3 bucket: must exist and be provided per canary
#
# To disable: set synthetics_canaries = {}
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "synthetics_canaries" {
  description = <<-EOT
    Map of CloudWatch Synthetics canaries for continuous endpoint monitoring.
    Each canary runs an HTTP check on a schedule and alarms if the endpoint fails.
    Key = canary logical name (also used as the canary display name).

    Example:
      api_health = {
        endpoint_url        = "https://api.example.com/health"
        schedule_expression = "rate(5 minutes)"
        s3_bucket           = "my-canary-artifacts-bucket"
        expected_http_code  = 200
        alarm_on_failure    = true
      }
      payment_checkout = {
        endpoint_url        = "https://checkout.example.com/status"
        schedule_expression = "rate(1 minute)"
        s3_bucket           = "my-canary-artifacts-bucket"
      }
  EOT
  type = map(object({
    endpoint_url          = string
    schedule_expression   = optional(string, "rate(5 minutes)")
    runtime_version       = optional(string, "syn-nodejs-puppeteer-7.0")
    s3_bucket             = string
    s3_prefix             = optional(string, "canary")
    expected_http_code    = optional(number, 200)
    timeout_in_seconds    = optional(number, 60)
    memory_in_mb          = optional(number, 960)
    active_tracing        = optional(bool, false)
    alarm_on_failure      = optional(bool, true)
    environment_variables = optional(map(string), {})
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "canary_execution_role_arn" {
  description = "IAM role ARN for Synthetics canary execution. Module auto-creates a role when null and canaries are defined."
  type        = string
  default     = null
}

# ── IAM Role for Canary Execution ─────────────────────────────────────────────

resource "aws_iam_role" "canary" {
  count = length(var.synthetics_canaries) > 0 && var.canary_execution_role_arn == null ? 1 : 0

  name = "${local.prefix}-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "canary_synthetics" {
  count = length(var.synthetics_canaries) > 0 && var.canary_execution_role_arn == null ? 1 : 0

  role       = aws_iam_role.canary[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

resource "aws_iam_role_policy" "canary_s3" {
  count = length(var.synthetics_canaries) > 0 && var.canary_execution_role_arn == null ? 1 : 0

  name = "${local.prefix}-canary-s3-access"
  role = aws_iam_role.canary[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:${data.aws_partition.current.partition}:logs:*:*:*"
      }
    ]
  })
}

locals {
  effective_canary_role_arn = var.canary_execution_role_arn != null ? var.canary_execution_role_arn : (
    length(var.synthetics_canaries) > 0 ? try(aws_iam_role.canary[0].arn, null) : null
  )
}

# ── Canary Script Archive ─────────────────────────────────────────────────────
# Packages a simple HTTP check Node.js script for each canary endpoint.

data "archive_file" "canary" {
  for_each = var.synthetics_canaries

  type        = "zip"
  output_path = "${path.module}/.canary_${replace(each.key, "-", "_")}.zip"

  source {
    content  = <<-JS
      const synthetics = require('Synthetics');
      const log = require('SyntheticsLogger');

      const httpCheck = async function () {
        const url = '${each.value.endpoint_url}';
        const expectedCode = ${each.value.expected_http_code};

        const response = await synthetics.executeHttpStep(
          'Verify ${each.key}',
          url,
          {
            method: 'GET',
            headers: {
              'User-Agent': 'CloudWatch Synthetics',
              'Accept': 'application/json, text/html, */*'
            }
          }
        );

        if (response.statusCode !== expectedCode) {
          throw new Error(
            'Endpoint check failed: expected HTTP ' + expectedCode +
            ' but received ' + response.statusCode + ' for ' + url
          );
        }

        log.info('Endpoint healthy: HTTP ' + response.statusCode + ' from ' + url);
        return response;
      };

      exports.handler = async () => {
        return await httpCheck();
      };
    JS
    filename = "nodejs/node_modules/pageLoadBlueprint.js"
  }
}

# ── Synthetics Canary Resources ───────────────────────────────────────────────

resource "aws_synthetics_canary" "this" {
  for_each = var.synthetics_canaries

  name                 = "${local.prefix}-${each.key}"
  artifact_s3_location = "s3://${each.value.s3_bucket}/${each.value.s3_prefix}/"
  execution_role_arn   = local.effective_canary_role_arn
  runtime_version      = each.value.runtime_version
  start_canary         = true
  handler              = "pageLoadBlueprint.handler"

  schedule {
    expression = each.value.schedule_expression
  }

  run_config {
    timeout_in_seconds    = each.value.timeout_in_seconds
    memory_in_mb          = each.value.memory_in_mb
    active_tracing        = each.value.active_tracing
    environment_variables = each.value.environment_variables
  }

  artifact_config {
    s3_encryption {
      encryption_mode = "SSE_S3"
    }
  }

  zip_file = data.archive_file.canary[each.key].output_path

  tags = merge(local.common_tags, each.value.tags)

  depends_on = [
    aws_iam_role_policy_attachment.canary_synthetics,
    aws_iam_role_policy.canary_s3
  ]
}

# ── Canary Failure Alarms ─────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "canary" {
  for_each = { for k, v in var.synthetics_canaries : k => v if v.alarm_on_failure }

  alarm_name          = "${local.prefix}-canary-${each.key}-failed"
  alarm_description   = "Synthetics canary '${local.prefix}-${each.key}' is FAILING — endpoint ${each.value.endpoint_url} is not responding as expected. Check canary results in the CloudWatch Synthetics console."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  treat_missing_data  = "breaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.this[each.key].name
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "synthetics" })
}
