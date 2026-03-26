variable "name" {
  description = "Name of the CodeBuild project."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to the name."
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the CodeBuild project."
  type        = string
  default     = "Managed by Terraform"
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

variable "build_timeout" {
  description = "Build timeout in minutes."
  type        = number
  default     = 60
}

variable "queued_timeout" {
  description = "Queued timeout in minutes."
  type        = number
  default     = 480
}

variable "source_type" {
  description = "Source type: GITHUB, BITBUCKET, CODECOMMIT, S3, NO_SOURCE."
  type        = string
  default     = "NO_SOURCE"
  validation {
    condition     = contains(["GITHUB", "GITHUB_ENTERPRISE", "BITBUCKET", "CODECOMMIT", "S3", "NO_SOURCE"], var.source_type)
    error_message = "Invalid source_type."
  }
}

variable "source_location" {
  description = "Source location URL or S3 URI. Leave empty for NO_SOURCE."
  type        = string
  default     = ""
}

variable "source_version" {
  description = "Branch, tag, or commit SHA for Git sources."
  type        = string
  default     = null
}

variable "buildspec" {
  description = "Inline buildspec YAML. Leave empty to use buildspec.yml from source."
  type        = string
  default     = ""
}

variable "git_clone_depth" {
  description = "Git clone depth. 0 = full clone."
  type        = number
  default     = 1
}

variable "compute_type" {
  description = "CodeBuild compute type."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE", "BUILD_GENERAL1_2XLARGE", "BUILD_LAMBDA_1GB", "BUILD_LAMBDA_2GB", "BUILD_LAMBDA_4GB", "BUILD_LAMBDA_8GB", "BUILD_LAMBDA_10GB"], var.compute_type)
    error_message = "Invalid compute_type."
  }
}

variable "image" {
  description = "CodeBuild image. Use 'aws/codebuild/standard:7.0' for Linux x86, 'aws/codebuild/amazonlinux-aarch64-standard:3.0' for ARM64."
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "image_type" {
  description = "Environment type: LINUX_CONTAINER, ARM_CONTAINER, LINUX_GPU_CONTAINER."
  type        = string
  default     = "LINUX_CONTAINER"
  validation {
    condition     = contains(["LINUX_CONTAINER", "ARM_CONTAINER", "LINUX_GPU_CONTAINER", "WINDOWS_SERVER_2019_CONTAINER"], var.image_type)
    error_message = "Invalid image_type."
  }
}

variable "privileged_mode" {
  description = "Enable privileged mode (required for Docker builds)."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Build environment variables. Map of name => { value, type }. Type: PLAINTEXT, PARAMETER_STORE, SECRETS_MANAGER."
  type = map(object({
    value = string
    type  = optional(string, "PLAINTEXT")
  }))
  default = {}
}

variable "artifacts_type" {
  description = "Artifacts type: NO_ARTIFACTS or S3."
  type        = string
  default     = "NO_ARTIFACTS"
  validation {
    condition     = contains(["NO_ARTIFACTS", "S3"], var.artifacts_type)
    error_message = "artifacts_type must be NO_ARTIFACTS or S3."
  }
}

variable "artifacts_bucket" {
  description = "S3 bucket for artifacts. Required when artifacts_type = S3."
  type        = string
  default     = null
}

variable "artifacts_path" {
  description = "S3 path prefix for artifacts."
  type        = string
  default     = ""
}

variable "cache_type" {
  description = "Cache type: NO_CACHE, LOCAL, S3."
  type        = string
  default     = "NO_CACHE"
}

variable "cache_bucket" {
  description = "S3 bucket for S3 cache."
  type        = string
  default     = null
}

variable "cache_modes" {
  description = "Local cache modes: LOCAL_SOURCE_CACHE, LOCAL_DOCKER_LAYER_CACHE, LOCAL_CUSTOM_CACHE."
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for build output."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "enable_s3_logs" {
  description = "Enable S3 logging for build output."
  type        = bool
  default     = false
}

variable "s3_logs_bucket" {
  description = "S3 bucket for build logs."
  type        = string
  default     = null
}

variable "s3_logs_prefix" {
  description = "S3 prefix for build logs."
  type        = string
  default     = "codebuild-logs"
}

variable "vpc_id" {
  description = "VPC ID for builds inside a VPC. Null = outside VPC."
  type        = string
  default     = null
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for CodeBuild inside VPC."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for CodeBuild inside VPC."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting build artifacts."
  type        = string
  default     = null
}

variable "additional_policy_statements" {
  description = "Additional IAM policy statements for the CodeBuild service role."
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}
