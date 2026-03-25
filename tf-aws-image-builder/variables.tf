variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
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
  type = map(string)
  default = {
  }
}

# ===========================================================================
# IMAGE RECIPE
# ===========================================================================
variable "platform" {
  description = "Linux or Windows."
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.platform)
    error_message = "platform must be 'Linux' or 'Windows'."
  }
}

variable "recipe_version" {
  description = "Semantic version for the image recipe, e.g. 1.0.0."
  type        = string
  default     = "1.0.0"
}

variable "parent_image" {
  description = "Base AMI ID or Image Builder ARN. Leave null for managed defaults."
  type        = string
  default     = null
}

variable "linux_parent_image_ssm" {
  description = "SSM path for latest Amazon Linux 2023 AMI (Linux default)."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "windows_parent_image_ssm" {
  description = "SSM path for latest Windows Server 2022 AMI (Windows default)."
  type        = string
  default     = "arn:aws:imagebuilder:us-east-1:aws:image/windows-server-2022-english-full-base-x86/x.x.x"
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "root_volume_type" {
  type    = string
  default = "gp3"
}

variable "kms_key_arn" {
  description = "KMS key for volume encryption in the recipe."
  type        = string
  default     = null
}

# ===========================================================================
# COMPONENTS
# ===========================================================================
variable "components" {
  description = "List of Image Builder component ARNs to include in the recipe."
  type = list(object({
    component_arn = string
    parameters = optional(
      list(object({
        name  = string
        value = list(string)
    })), [])
  }))
  default = []
}

variable "custom_components" {
  description = "Inline component definitions to create and include."
  type = map(object({
    platform    = optional(string, null) # defaults to var.platform
    version     = optional(string, "1.0.0")
    data        = string # YAML document (AWSTOE format)
    description = optional(string, "")
  }))
  default = {}
}

# ===========================================================================
# INFRASTRUCTURE
# ===========================================================================
variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "subnet_id" {
  description = "Subnet for build instances."
  type        = string
  default     = null
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "terminate_on_failure" {
  type    = bool
  default = true
}

variable "sns_topic_arn" {
  description = "SNS topic for pipeline notifications."
  type        = string
  default     = null
}

# ===========================================================================
# DISTRIBUTION
# ===========================================================================
variable "distribution_regions" {
  description = "Regions to copy the AMI to after build."
  type        = list(string)
  default     = []
}

variable "ami_name_prefix" {
  description = "Prefix for the distributed AMI name."
  type        = string
  default     = ""
}

variable "ami_launch_permissions" {
  description = "AWS account IDs to share the AMI with."
  type        = list(string)
  default     = []
}

# ===========================================================================
# PIPELINE SCHEDULE
# ===========================================================================
variable "pipeline_schedule_expression" {
  description = "cron or rate expression for automated pipeline runs. null = manual only."
  type        = string
  default     = null
}

variable "pipeline_timezone" {
  type    = string
  default = "UTC"
}

variable "pipeline_enabled" {
  type    = bool
  default = true
}

# ===========================================================================
# SOFTWARE OPTIONS — pre-built component toggles
# Components YAML files live in components/linux/ and components/windows/
# ===========================================================================
variable "install_cloudwatch_agent" {
  description = "Install Amazon CloudWatch Agent."
  type        = bool
  default     = true
}

variable "cloudwatch_agent_ssm_param" {
  description = "SSM parameter path for CloudWatch Agent config."
  type        = string
  default     = "AmazonCloudWatch-linux"
}

variable "install_dynatrace" {
  description = "Install Dynatrace OneAgent."
  type        = bool
  default     = false
}

variable "dynatrace_env_url" {
  description = "Dynatrace environment URL (required when install_dynatrace = true)."
  type        = string
  default     = ""
}

variable "dynatrace_api_token" {
  description = "Dynatrace PaaS token (required when install_dynatrace = true). Store in SSM/Secrets Manager."
  type        = string
  default     = ""
  sensitive   = true
}

variable "install_oracle_client" {
  description = "Install Oracle Instant Client."
  type        = bool
  default     = false
}

variable "oracle_client_version" {
  type    = string
  default = "21.12"
}

variable "oracle_client_s3_bucket" {
  description = "S3 bucket with Oracle RPM/ZIP packages. Empty = download from Oracle public CDN."
  type        = string
  default     = ""
}

variable "install_iis" {
  description = "Install IIS (Windows only)."
  type        = bool
  default     = false
}

variable "iis_enable_aspnet48" {
  type    = bool
  default = true
}

variable "iis_enable_aspnet_core" {
  type    = bool
  default = true
}

variable "install_grafana_agent" {
  description = "Install Grafana Agent (metrics/logs forwarder)."
  type        = bool
  default     = false
}

variable "grafana_agent_version" {
  type    = string
  default = "v0.40.0"
}
