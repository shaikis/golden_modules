# ── Feature Gates ─────────────────────────────────────────────────────────────
# Set to true only for features you need. Simple setups only need identities.

variable "create_configuration_sets" {
  description = "Set true to create SES configuration sets and event destinations."
  type        = bool
  default     = false
}

variable "create_receipt_rules" {
  description = "Set true to create inbound receipt rule sets and rules."
  type        = bool
  default     = false
}

variable "create_templates" {
  description = "Set true to create SES email templates."
  type        = bool
  default     = false
}

variable "create_iam_roles" {
  description = "Set true to auto-create IAM roles for SES->Firehose and SES->S3."
  type        = bool
  default     = false
}

variable "create_data_catalogs" {
  description = "Reserved for future federated catalog support."
  type        = bool
  default     = false
}

# ── Identity Variables ─────────────────────────────────────────────────────────

variable "domain_identities" {
  description = "Map of domain identities to create in SES. Key is a logical name; domain is the actual domain string."
  type = map(object({
    domain                           = string
    dkim_signing                     = optional(bool, true)
    mail_from_domain                 = optional(string, null)
    mail_from_behavior_on_mx_failure = optional(string, "USE_DEFAULT_VALUE")
    configuration_set_name           = optional(string, null)
    tags                             = optional(map(string), {})
  }))
  default = {}
}

variable "email_identities" {
  description = "Map of email address identities to create in SES."
  type = map(object({
    email_address          = string
    configuration_set_name = optional(string, null)
  }))
  default = {}
}

variable "configuration_sets" {
  description = "Map of SES v2 configuration sets and their event destinations."
  type = map(object({
    sending_enabled            = optional(bool, true)
    reputation_metrics_enabled = optional(bool, true)
    suppression_reasons        = optional(list(string), ["BOUNCE", "COMPLAINT"])
    engagement_metrics         = optional(bool, false)
    optimized_shared_delivery  = optional(bool, false)
    custom_redirect_domain     = optional(string, null)
    tags                       = optional(map(string), {})
    event_destinations = optional(map(object({
      enabled     = optional(bool, true)
      event_types = list(string)
      sns_destination = optional(object({
        topic_arn = string
      }), null)
      cloudwatch_destination = optional(object({
        dimension_configurations = list(object({
          dimension_name          = string
          dimension_value_source  = string
          default_dimension_value = string
        }))
      }), null)
      kinesis_firehose_destination = optional(object({
        delivery_stream_arn = string
        iam_role_arn        = optional(string, null)
      }), null)
      pinpoint_destination = optional(object({
        application_arn = string
      }), null)
    })), {})
  }))
  default = {}
}

variable "rule_sets" {
  description = "Map of SES receipt rule sets. Key is the rule set name. Set active=true to make it the active rule set."
  type = map(object({
    active = optional(bool, false)
  }))
  default = {}
}

variable "receipt_rules" {
  description = "Map of SES receipt rules. Each rule must reference an existing rule_set_name."
  type = map(object({
    rule_set_name = string
    recipients    = list(string)
    enabled       = optional(bool, true)
    scan_enabled  = optional(bool, true)
    tls_policy    = optional(string, "Optional")
    after         = optional(string, null)
    s3_actions = optional(list(object({
      bucket_name = string
      key_prefix  = optional(string, "")
      kms_key_arn = optional(string, null)
      position    = number
    })), [])
    sns_actions = optional(list(object({
      topic_arn = string
      position  = number
    })), [])
    lambda_actions = optional(list(object({
      function_arn    = string
      invocation_type = optional(string, "Event")
      position        = number
    })), [])
    bounce_actions = optional(list(object({
      message         = string
      sender          = string
      smtp_reply_code = string
      status_code     = optional(string, null)
      topic_arn       = optional(string, null)
      position        = number
    })), [])
    stop_actions = optional(list(object({
      scope     = string
      topic_arn = optional(string, null)
      position  = number
    })), [])
    workmail_actions = optional(list(object({
      organization_arn = string
      topic_arn        = optional(string, null)
      position         = number
    })), [])
    add_header_actions = optional(list(object({
      header_name  = string
      header_value = string
      position     = number
    })), [])
  }))
  default = {}
}

variable "templates" {
  description = "Map of SES email templates. Key is the template name."
  type = map(object({
    subject   = string
    html_part = optional(string, null)
    text_part = optional(string, null)
  }))
  default = {}
}

# ── IAM / BYO ──────────────────────────────────────────────────────────────────

variable "create_firehose_role" {
  description = "Set to true to auto-create the IAM role that allows SES to write to Kinesis Firehose. Controlled by create_iam_roles when not set explicitly."
  type        = bool
  default     = false
}

variable "create_s3_role" {
  description = "Set to true to auto-create the IAM role that allows SES to deliver inbound mail to S3. Controlled by create_iam_roles when not set explicitly."
  type        = bool
  default     = false
}

variable "firehose_role_name" {
  description = "Override name for the SES→Firehose IAM role. Defaults to 'ses-firehose-delivery-role'."
  type        = string
  default     = "ses-firehose-delivery-role"
}

variable "s3_role_name" {
  description = "Override name for the SES→S3 IAM role. Defaults to 'ses-s3-inbound-role'."
  type        = string
  default     = "ses-s3-inbound-role"
}

variable "sending_identity_arns" {
  description = "List of SES identity ARNs to include in the sending IAM policy document (ses:SendEmail / ses:SendRawEmail)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Default tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}
