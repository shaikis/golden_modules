# ===========================================================================
# AWS INSPECTOR V2 — Enable on current account
# ===========================================================================
resource "aws_inspector2_enabler" "this" {
  account_ids = ["${data.aws_caller_identity.current.account_id}"]

  resource_types = compact([
    var.enable_ec2_scanning     ? "EC2"             : "",
    var.enable_ecr_scanning     ? "ECR"             : "",
    var.enable_lambda_scanning  ? "LAMBDA"          : "",
    var.enable_lambda_code_scanning ? "LAMBDA_CODE" : "",
  ])
}

# ===========================================================================
# DELEGATED ADMINISTRATOR (Organizations)
# ===========================================================================
resource "aws_inspector2_delegated_admin_account" "this" {
  count      = var.enable_delegated_admin ? 1 : 0
  account_id = var.delegated_admin_account_id
}

# ===========================================================================
# MEMBER ACCOUNT ASSOCIATIONS
# ===========================================================================
resource "aws_inspector2_member_association" "this" {
  for_each   = { for m in var.member_accounts : m.account_id => m }
  account_id = each.key

  depends_on = [aws_inspector2_delegated_admin_account.this]
}

# ===========================================================================
# FINDINGS EXPORT TO S3
# ===========================================================================
resource "aws_inspector2_findings_report" "this" {
  count = var.enable_findings_export ? 1 : 0

  report_format = "JSON"

  s3_destination {
    bucket_name = var.findings_export_bucket_name
    kms_key_arn = var.findings_export_kms_key_arn
  }

  filter_criteria {
    aws_account_id {
      comparison = "EQUALS"
      value      = data.aws_caller_identity.current.account_id
    }
  }
}

# ===========================================================================
# FINDINGS NOTIFICATIONS — EventBridge → SNS
# ===========================================================================
resource "aws_cloudwatch_event_rule" "inspector_findings" {
  count       = var.enable_findings_notifications ? 1 : 0
  name        = "${local.name}-inspector-findings"
  description = "Forward Inspector v2 findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
    detail = {
      severity = var.findings_severity_filter
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "inspector_sns" {
  count     = var.enable_findings_notifications ? 1 : 0
  rule      = aws_cloudwatch_event_rule.inspector_findings[0].name
  target_id = "InspectorFindingsSNS"
  arn       = var.findings_sns_topic_arn
}

resource "aws_sns_topic_policy" "inspector" {
  count = var.enable_findings_notifications && var.findings_sns_topic_arn != null ? 1 : 0
  arn   = var.findings_sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgeToPublish"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "sns:Publish"
      Resource = var.findings_sns_topic_arn
    }]
  })
}

# ===========================================================================
# SUPPRESSION RULES
# ===========================================================================
resource "aws_inspector2_filter" "suppression" {
  for_each = { for r in var.suppression_rules : r.name => r }

  name        = "${local.name}-${each.key}"
  description = each.value.description
  action      = "SUPPRESS"
  reason      = each.value.reason

  dynamic "filter_criteria" {
    for_each = each.value.filters
    content {
      dynamic "vulnerability_id" {
        for_each = filter_criteria.value.vulnerability_id
        content {
          comparison = "EQUALS"
          value      = vulnerability_id.value
        }
      }

      dynamic "resource_type" {
        for_each = filter_criteria.value.resource_type
        content {
          comparison = "EQUALS"
          value      = resource_type.value
        }
      }

      dynamic "severity" {
        for_each = filter_criteria.value.severity
        content {
          comparison = "EQUALS"
          value      = severity.value
        }
      }
    }
  }

  tags = local.tags
}
