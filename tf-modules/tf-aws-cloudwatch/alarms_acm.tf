# =============================================================================
# tf-aws-cloudwatch — ACM Certificate Expiry Alarms
#
# AWS ACM automatically emits the metric DaysToExpiry for each certificate.
# Creates two alarms per certificate:
#   - Warning:  fires N days before expiry (default 30 days)
#   - Critical: fires N days before expiry (default 7 days)
#
# Why this matters:
#   Expired TLS certificates cause immediate outages — browsers refuse to connect,
#   API clients fail, and monitoring/health checks report failures.
#   ACM auto-renews managed certificates, but ONLY if DNS/email validation passes.
#   This alarm catches cases where auto-renewal silently fails.
#
# To enable: add certificate ARNs to acm_certificate_arns
# To disable: set acm_certificate_arns = []
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "acm_certificate_arns" {
  description = <<-EOT
    List of ACM certificate ARNs to monitor for upcoming expiry.
    Creates warning + critical alarms for each certificate.
    Example:
      acm_certificate_arns = [
        "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "arn:aws:acm:us-east-1:123456789012:certificate/yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
      ]
  EOT
  type        = list(string)
  default     = []
}

variable "acm_expiry_warning_days" {
  description = "Trigger WARNING alarm when certificate expires within this many days."
  type        = number
  default     = 30
}

variable "acm_expiry_critical_days" {
  description = "Trigger CRITICAL alarm when certificate expires within this many days."
  type        = number
  default     = 7
}

# ── Certificate Expiry Warning ────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "acm_expiry_warning" {
  count = length(var.acm_certificate_arns)

  alarm_name          = "${local.prefix}-acm-cert-${count.index}-expiry-warning"
  alarm_description   = "ACM certificate ${var.acm_certificate_arns[count.index]} expires in < ${var.acm_expiry_warning_days} days. Verify ACM auto-renewal is configured and DNS/email validation is working."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400 # check daily
  statistic           = "Minimum"
  threshold           = var.acm_expiry_warning_days
  treat_missing_data  = "breaching"

  dimensions = {
    CertificateArn = var.acm_certificate_arns[count.index]
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "acm" })
}

# ── Certificate Expiry Critical ───────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "acm_expiry_critical" {
  count = length(var.acm_certificate_arns)

  alarm_name          = "${local.prefix}-acm-cert-${count.index}-expiry-critical"
  alarm_description   = "CRITICAL: ACM certificate ${var.acm_certificate_arns[count.index]} expires in < ${var.acm_expiry_critical_days} days! Immediate action required to prevent service outage."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400 # check daily
  statistic           = "Minimum"
  threshold           = var.acm_expiry_critical_days
  treat_missing_data  = "breaching"

  dimensions = {
    CertificateArn = var.acm_certificate_arns[count.index]
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "acm" })
}
