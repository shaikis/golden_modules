variable "name" {
  description = "Module name used for resource naming."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = ""
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ===========================================================================
# SCAN TYPES
# ===========================================================================
variable "enable_ec2_scanning" {
  description = "Enable EC2 instance vulnerability scanning."
  type        = bool
  default     = true
}

variable "enable_ecr_scanning" {
  description = "Enable ECR container image scanning."
  type        = bool
  default     = true
}

variable "enable_lambda_scanning" {
  description = "Enable Lambda function code vulnerability scanning."
  type        = bool
  default     = false
}

variable "enable_lambda_code_scanning" {
  description = "Enable Lambda code scanning (in addition to standard Lambda scanning)."
  type        = bool
  default     = false
}

# ===========================================================================
# DELEGATED ADMINISTRATOR (Organizations)
# ===========================================================================
variable "enable_delegated_admin" {
  description = "Designate this account as the Inspector delegated administrator for an AWS Organization."
  type        = bool
  default     = false
}

variable "delegated_admin_account_id" {
  description = "Account ID to designate as delegated administrator. Required when enable_delegated_admin = true."
  type        = string
  default     = null
}

variable "member_accounts" {
  description = <<-EOT
    List of member accounts to enable Inspector on (requires delegated admin setup).
      account_id - AWS account ID
  EOT
  type = list(object({
    account_id = string
  }))
  default = []
}

# ===========================================================================
# FINDINGS EXPORT — EventBridge → SNS
# ===========================================================================
variable "enable_findings_notifications" {
  description = "Create EventBridge rule to forward Inspector findings to SNS."
  type        = bool
  default     = false
}

variable "findings_sns_topic_arn" {
  description = "SNS topic ARN to publish Inspector findings to. Required when enable_findings_notifications = true."
  type        = string
  default     = null
}

variable "findings_severity_filter" {
  description = "Only forward findings at or above this severity. Values: INFORMATIONAL | LOW | MEDIUM | HIGH | CRITICAL"
  type        = list(string)
  default     = ["HIGH", "CRITICAL"]
}

# ===========================================================================
# FINDINGS EXPORT — S3 (via EventBridge → Lambda is out of scope; use native export)
# ===========================================================================
variable "enable_findings_export" {
  description = "Enable continuous findings export to S3 via AWS Inspector native export."
  type        = bool
  default     = false
}

variable "findings_export_bucket_name" {
  description = "S3 bucket name for Inspector findings export. Required when enable_findings_export = true."
  type        = string
  default     = null
}

variable "findings_export_kms_key_arn" {
  description = "KMS key ARN for encrypting exported findings."
  type        = string
  default     = null
}

# ===========================================================================
# SUPPRESSION RULES (false-positive management)
# ===========================================================================
variable "suppression_rules" {
  description = <<-EOT
    List of finding suppression rules. Each rule:
      name        - rule name
      description - optional description
      reason      - reason for suppression: ACCEPTED_RISK | FALSE_POSITIVE
      filters     - one or more filter criteria maps. Supported keys:
        vulnerability_id  - list of CVE IDs
        resource_type     - list of resource types (AWS_EC2_INSTANCE | AWS_ECR_CONTAINER_IMAGE | AWS_LAMBDA_FUNCTION)
        severity          - list of severities
        title             - title string filter (comparison: PREFIX | EQUALS | NOT_EQUALS)
  EOT
  type = list(object({
    name        = string
    description = optional(string, "")
    reason      = string
    filters = list(object({
      vulnerability_id = optional(list(string), [])
      resource_type    = optional(list(string), [])
      severity         = optional(list(string), [])
    }))
  }))
  default = []
}
