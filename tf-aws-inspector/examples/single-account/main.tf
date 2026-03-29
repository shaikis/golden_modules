# =============================================================================
# SCENARIO: Single-Account Security — Startup / SMB
#
# A startup running workloads in a single AWS account wants:
#   - Continuous CVE scanning of all EC2 instances (via SSM)
#   - Automatic ECR image scanning on push and continuously
#   - Lambda function dependency scanning
#   - Immediate Slack/PagerDuty alerts for HIGH and CRITICAL findings
#   - Suppress a known false-positive CVE in the OS package list
# =============================================================================

provider "aws" { region = var.aws_region }

# SNS topic for security alerts (wired to Slack / PagerDuty externally)
resource "aws_sns_topic" "security_alerts" {
  name = "${var.name}-security-alerts"
}

module "inspector" {
  source      = "../../"
  name        = "platform-security"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  # Scan all supported compute types
  enable_ec2_scanning         = true
  enable_ecr_scanning         = true
  enable_lambda_scanning      = true
  enable_lambda_code_scanning = true

  # Push HIGH/CRITICAL findings to SNS → Slack/PagerDuty
  enable_findings_notifications = true
  findings_sns_topic_arn        = aws_sns_topic.security_alerts.arn
  findings_severity_filter      = ["HIGH", "CRITICAL"]

  # False-positive: internal tooling uses a vendored libcurl version
  # that ships with a patched CVE not yet reflected in the NVD database
  suppression_rules = [
    {
      name        = "libcurl-internal-tooling-fp"
      description = "CVE-2023-38545 patched in our build but NVD not updated yet"
      reason      = "FALSE_POSITIVE"
      filters = [
        {
          vulnerability_id = ["CVE-2023-38545"]
          resource_type    = ["AWS_EC2_INSTANCE"]
        }
      ]
    }
  ]
}

output "enabled_resource_types"  { value = module.inspector.enabled_resource_types }
output "findings_event_rule_arn" { value = module.inspector.findings_event_rule_arn }
output "suppression_rule_arns"   { value = module.inspector.suppression_rule_arns }
