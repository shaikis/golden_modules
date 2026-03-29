# =============================================================================
# SCENARIO: Enterprise Multi-Account Organization Security
#
# A large enterprise uses AWS Organizations with 50+ accounts across
# Business Units: Engineering, Finance, HR, Marketing.
# Central Security team requirements:
#   - Security account is the delegated Inspector admin
#   - All member accounts enrolled automatically (shown explicitly here)
#   - All findings centralized and exported to a Security Data Lake (S3)
#   - CRITICAL findings alert the SOC via SNS (PagerDuty integration)
#   - Suppress accepted risks (EOL packages approved by risk committee)
#   - EC2 + ECR scanning only (Lambda not used org-wide)
# =============================================================================

provider "aws" {
  region = var.aws_region
  # This provider runs in the SECURITY (delegated admin) account
}

# S3 bucket for centralized findings data lake
resource "aws_s3_bucket" "findings_lake" {
  bucket        = "${var.name}-inspector-findings-${var.security_account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "findings_lake" {
  bucket = aws_s3_bucket.findings_lake.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "findings_lake" {
  bucket = aws_s3_bucket.findings_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# SNS topic for SOC CRITICAL alerts
resource "aws_sns_topic" "soc_critical" {
  name              = "${var.name}-soc-critical-findings"
  kms_master_key_id = var.kms_key_arn
}

module "inspector_org" {
  source      = "../../"
  name        = "org-security"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  # Only EC2 and ECR across the organization
  enable_ec2_scanning    = true
  enable_ecr_scanning    = true
  enable_lambda_scanning = false

  # Designate the security account as delegated admin
  enable_delegated_admin     = true
  delegated_admin_account_id = var.security_account_id

  # Enroll all business unit accounts
  member_accounts = [
    { account_id = var.engineering_account_id },
    { account_id = var.finance_account_id },
    { account_id = var.hr_account_id },
    { account_id = var.marketing_account_id },
  ]

  # Export all findings to the Security Data Lake
  enable_findings_export      = true
  findings_export_bucket_name = aws_s3_bucket.findings_lake.bucket
  findings_export_kms_key_arn = var.kms_key_arn

  # Alert SOC only on CRITICAL findings (HIGH go to S3 + dashboards)
  enable_findings_notifications = true
  findings_sns_topic_arn        = aws_sns_topic.soc_critical.arn
  findings_severity_filter      = ["CRITICAL"]

  # Accepted risks approved by risk committee (tracked in risk register)
  suppression_rules = [
    {
      name        = "hr-legacy-app-accepted-risk"
      description = "HR legacy COBOL app CVEs — accepted risk, migration Q4 2025 (Risk-2024-047)"
      reason      = "ACCEPTED_RISK"
      filters = [
        {
          vulnerability_id = ["CVE-2021-44228", "CVE-2021-45046"] # Log4Shell
          resource_type    = ["AWS_EC2_INSTANCE"]
          severity         = ["HIGH"]
        }
      ]
    },
    {
      name        = "base-image-false-positive"
      description = "Base AMI CVE — patched in our hardened AMI pipeline but scanner lags"
      reason      = "FALSE_POSITIVE"
      filters = [
        {
          vulnerability_id = ["CVE-2023-0286"]
          resource_type    = ["AWS_EC2_INSTANCE"]
        }
      ]
    },
    {
      name        = "marketing-ecr-informational"
      description = "Marketing team ECR images — INFO findings accepted per policy"
      reason      = "ACCEPTED_RISK"
      filters = [
        {
          resource_type = ["AWS_ECR_CONTAINER_IMAGE"]
          severity      = ["INFORMATIONAL", "LOW"]
        }
      ]
    }
  ]
}

output "delegated_admin_account_id" { value = module.inspector_org.delegated_admin_account_id }
output "member_account_ids"         { value = module.inspector_org.member_account_ids }
output "suppression_rule_arns"      { value = module.inspector_org.suppression_rule_arns }
output "findings_bucket"            { value = aws_s3_bucket.findings_lake.bucket }
