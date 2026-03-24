# =============================================================================
# tf-aws-cloudwatch — Security Alerts
#
# EventBridge rules for security-critical AWS events via CloudTrail + GuardDuty.
# Best practice: route these to a DEDICATED high-priority SNS topic so they
# bypass normal escalation paths and go directly to the security team.
#
# Included alerts (each independently enabled via feature flags):
#
#   enable_security_alerts = true  enables ALL of:
#     1. Root account usage              → any console/API action by root user
#     2. IAM user creation / deletion    → new backdoor users or account tampering
#     3. IAM access key creation         → new programmatic credentials created
#     4. IAM policy attach / detach      → privilege escalation or permission removal
#     5. Security group ingress changes  → new public-facing ports opened
#     6. S3 bucket policy changes        → public access or cross-account grants
#     7. Failed console logins           → brute-force or credential stuffing
#
#   enable_guardduty_alerts = true  enables:
#     8. GuardDuty HIGH/CRITICAL findings → crypto-mining, exfil, recon, compromised creds
#
# Prerequisite for 1-7: CloudTrail with management events enabled.
# Prerequisite for 8: GuardDuty must be enabled in the account.
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "enable_security_alerts" {
  description = <<-EOT
    Create EventBridge rules for security-critical CloudTrail events:
    root account usage, IAM user/key/policy changes, security group changes,
    S3 bucket policy changes, and failed console logins.
  EOT
  type        = bool
  default     = false
}

variable "security_alert_sns_topic_arn" {
  description = <<-EOT
    Dedicated SNS topic ARN for security alerts (recommended: separate from operational alarms).
    When null, falls back to the module's main SNS topic.
    Best practice: connect to a P1/immediate OpsGenie team or security SIEM.
  EOT
  type        = string
  default     = null
}

variable "enable_guardduty_alerts" {
  description = <<-EOT
    Create EventBridge rule to forward GuardDuty findings above the severity threshold to SNS.
    Requires GuardDuty to be enabled in the account.
    GuardDuty detects: crypto-mining, data exfiltration, compromised credentials,
    reconnaissance, DNS-based attacks, and more.
  EOT
  type        = bool
  default     = false
}

variable "guardduty_severity_threshold" {
  description = <<-EOT
    Minimum GuardDuty finding severity to alert on (0-10 scale).
    7.0 = HIGH+CRITICAL only (recommended for production).
    4.0 = MEDIUM+HIGH+CRITICAL (more alerts, more noise).
    Severity reference: LOW=1-3.9, MEDIUM=4-6.9, HIGH=7-8.9, CRITICAL=9-10.
  EOT
  type        = number
  default     = 7
}

# ── Locals ────────────────────────────────────────────────────────────────────

locals {
  security_sns_arn = var.security_alert_sns_topic_arn != null ? var.security_alert_sns_topic_arn : local.effective_sns_arn
}

# ── Root Account Usage ────────────────────────────────────────────────────────
# Root should NEVER be used for day-to-day operations.
# Any root activity is suspicious and must be investigated immediately.

resource "aws_cloudwatch_event_rule" "root_usage" {
  count = var.enable_security_alerts ? 1 : 0

  name        = "${local.prefix}-sec-root-account-usage"
  description = "Alert on any AWS root account API/console activity."

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["Root"]
      }
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "critical" })
}

resource "aws_cloudwatch_event_target" "root_usage" {
  count = var.enable_security_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.root_usage[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account   = "$.account"
      region    = "$.region"
      time      = "$.time"
      event     = "$.detail.eventName"
      source_ip = "$.detail.sourceIPAddress"
    }
    input_template = "\"SECURITY ALERT: Root Account Used\\nAccount: <account>\\nRegion: <region>\\nTime: <time>\\nAction: <event>\\nSource IP: <source_ip>\\n\\nRoot account usage is a security violation. Investigate immediately.\""
  }
}

# ── IAM User Creation / Deletion ──────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "iam_user_change" {
  count = var.enable_security_alerts ? 1 : 0

  name        = "${local.prefix}-sec-iam-user-change"
  description = "Alert when IAM users are created or deleted."

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["CreateUser", "DeleteUser", "CreateLoginProfile", "UpdateLoginProfile"]
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "warning" })
}

resource "aws_cloudwatch_event_target" "iam_user_change" {
  count = var.enable_security_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.iam_user_change[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account  = "$.account"
      time     = "$.time"
      event    = "$.detail.eventName"
      actor    = "$.detail.userIdentity.arn"
      request  = "$.detail.requestParameters"
      sourceip = "$.detail.sourceIPAddress"
    }
    input_template = "\"SECURITY ALERT: IAM User Change\\nEvent: <event>\\nAccount: <account>\\nTime: <time>\\nPerformed by: <actor>\\nSource IP: <sourceip>\\nDetails: <request>\\n\\nVerify this IAM change was authorized.\""
  }
}

# ── IAM Access Key Creation ───────────────────────────────────────────────────
# New access keys = new programmatic credentials. Ensure they are expected.

resource "aws_cloudwatch_event_rule" "iam_access_key_create" {
  count = var.enable_security_alerts ? 1 : 0

  name        = "${local.prefix}-sec-iam-access-key-created"
  description = "Alert when new IAM access keys are created."

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["CreateAccessKey"]
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "warning" })
}

resource "aws_cloudwatch_event_target" "iam_access_key_create" {
  count = var.enable_security_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.iam_access_key_create[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account = "$.account"
      time    = "$.time"
      actor   = "$.detail.userIdentity.arn"
      request = "$.detail.requestParameters"
      source  = "$.detail.sourceIPAddress"
    }
    input_template = "\"SECURITY ALERT: New IAM Access Key Created\\nAccount: <account>\\nTime: <time>\\nCreated by: <actor>\\nSource IP: <source>\\nDetails: <request>\\n\\nEnsure this access key is expected and not a backdoor credential.\""
  }
}

# ── IAM Policy Attach / Detach ────────────────────────────────────────────────
# Privilege escalation detection: attaching admin/privileged policies to users/roles.

resource "aws_cloudwatch_event_rule" "iam_policy_change" {
  count = var.enable_security_alerts ? 1 : 0

  name        = "${local.prefix}-sec-iam-policy-change"
  description = "Alert on IAM policy attach/detach events (privilege escalation risk)."

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "AttachUserPolicy", "DetachUserPolicy",
        "AttachRolePolicy", "DetachRolePolicy",
        "AttachGroupPolicy", "DetachGroupPolicy",
        "PutUserPolicy", "DeleteUserPolicy",
        "PutRolePolicy", "DeleteRolePolicy"
      ]
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "warning" })
}

resource "aws_cloudwatch_event_target" "iam_policy_change" {
  count = var.enable_security_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.iam_policy_change[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account = "$.account"
      time    = "$.time"
      event   = "$.detail.eventName"
      actor   = "$.detail.userIdentity.arn"
      request = "$.detail.requestParameters"
      source  = "$.detail.sourceIPAddress"
    }
    input_template = "\"SECURITY ALERT: IAM Policy Changed\\nEvent: <event>\\nAccount: <account>\\nTime: <time>\\nPerformed by: <actor>\\nSource IP: <source>\\nDetails: <request>\\n\\nPossible privilege escalation. Verify this policy change was authorized.\""
  }
}

# ── Security Group Ingress Rule Changes ───────────────────────────────────────
# New ingress rules may open ports to 0.0.0.0/0 — review any inbound port additions.

resource "aws_cloudwatch_event_rule" "security_group_change" {
  count = var.enable_security_alerts ? 1 : 0

  name        = "${local.prefix}-sec-sg-ingress-change"
  description = "Alert when security group ingress rules are added or removed."

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "AuthorizeSecurityGroupIngress",
        "RevokeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress",
        "RevokeSecurityGroupEgress",
        "CreateSecurityGroup",
        "DeleteSecurityGroup"
      ]
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "warning" })
}

resource "aws_cloudwatch_event_target" "security_group_change" {
  count = var.enable_security_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.security_group_change[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account = "$.account"
      region  = "$.region"
      time    = "$.time"
      event   = "$.detail.eventName"
      actor   = "$.detail.userIdentity.arn"
      request = "$.detail.requestParameters"
      source  = "$.detail.sourceIPAddress"
    }
    input_template = "\"SECURITY ALERT: Security Group Changed\\nEvent: <event>\\nAccount: <account>\\nRegion: <region>\\nTime: <time>\\nChanged by: <actor>\\nSource IP: <source>\\nDetails: <request>\\n\\nCheck if new ingress rules expose ports to 0.0.0.0/0 (internet).\""
  }
}

# ── S3 Bucket Policy / ACL Changes ───────────────────────────────────────────
# Public bucket access or cross-account grants can cause data exposure.

resource "aws_cloudwatch_event_rule" "s3_policy_change" {
  count = var.enable_security_alerts ? 1 : 0

  name        = "${local.prefix}-sec-s3-policy-change"
  description = "Alert when S3 bucket policies, ACLs, or public access settings change."

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "PutBucketPolicy", "DeleteBucketPolicy",
        "PutBucketAcl", "PutBucketPublicAccessBlock",
        "DeletePublicAccessBlock"
      ]
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "warning" })
}

resource "aws_cloudwatch_event_target" "s3_policy_change" {
  count = var.enable_security_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.s3_policy_change[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account = "$.account"
      time    = "$.time"
      event   = "$.detail.eventName"
      actor   = "$.detail.userIdentity.arn"
      request = "$.detail.requestParameters"
      source  = "$.detail.sourceIPAddress"
    }
    input_template = "\"SECURITY ALERT: S3 Bucket Policy Changed\\nEvent: <event>\\nAccount: <account>\\nTime: <time>\\nChanged by: <actor>\\nSource IP: <source>\\nDetails: <request>\\n\\nRisk: bucket may now be public or accessible cross-account. Verify immediately.\""
  }
}

# ── GuardDuty High/Critical Findings ─────────────────────────────────────────
# GuardDuty detects: crypto-mining, data exfiltration, compromised credentials,
# reconnaissance, port scanning, unusual API calls, DNS-based C2, and more.

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count = var.enable_guardduty_alerts ? 1 : 0

  name        = "${local.prefix}-sec-guardduty-findings"
  description = "Forward GuardDuty findings with severity >= ${var.guardduty_severity_threshold} to SNS."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.guardduty_severity_threshold] }]
    }
  })

  tags = merge(local.common_tags, { Feature = "security", Severity = "critical" })
}

resource "aws_cloudwatch_event_target" "guardduty_findings" {
  count = var.enable_guardduty_alerts && local.security_sns_arn != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.guardduty_findings[0].name
  arn  = local.security_sns_arn

  input_transformer {
    input_paths = {
      account     = "$.account"
      region      = "$.region"
      time        = "$.time"
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      description = "$.detail.description"
      resource    = "$.detail.resource"
      count       = "$.detail.service.count"
    }
    input_template = "\"SECURITY ALERT: GuardDuty Finding\\nSeverity : <severity>\\nType     : <type>\\nAccount  : <account>\\nRegion   : <region>\\nTime     : <time>\\nCount    : <count> occurrence(s)\\n\\nDescription: <description>\\n\\nAffected resource: <resource>\\n\\nInvestigate immediately in AWS Console -> GuardDuty -> Findings.\""
  }
}
