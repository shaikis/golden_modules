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
  type    = map(string)
  default = {
} }

# ===========================================================================
# REPOSITORIES
# ===========================================================================
variable "repositories" {
  description = "Map of repository name → config. Each creates one ECR repo."
  type = map(object({
    image_tag_mutability    = optional(string, "IMMUTABLE")
    scan_on_push            = optional(bool, true)
    force_delete            = optional(bool, false)
    encryption_type         = optional(string, "KMS")  # AES256 or KMS
    additional_tags         = optional(map(string), {})
  }))
  default = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for repository encryption (required when encryption_type = KMS)."
  type        = string
  default     = null
}

# ===========================================================================
# ACCESS POLICY
# ===========================================================================
variable "cross_account_ids" {
  description = "AWS account IDs to grant pull access."
  type        = list(string)
  default     = []
}

variable "additional_pull_principals" {
  description = "Additional IAM principal ARNs for pull access."
  type        = list(string)
  default     = []
}

variable "push_principal_arns" {
  description = "IAM principal ARNs that can push images (CI/CD roles)."
  type        = list(string)
  default     = []
}

# ===========================================================================
# LIFECYCLE POLICY
# ===========================================================================
variable "lifecycle_policy" {
  description = "ECR lifecycle policy JSON. Leave null to use the built-in policy."
  type        = string
  default     = null
}

variable "untagged_image_count" {
  description = "Keep this many untagged images; expire older ones."
  type        = number
  default     = 5
}

variable "tagged_image_count" {
  description = "Keep this many tagged images per prefix."
  type        = number
  default     = 30
}

variable "lifecycle_tag_prefixes" {
  description = "Image tag prefixes to apply the keep-count rule to."
  type        = list(string)
  default     = ["release", "v"]
}

# ===========================================================================
# REPLICATION
# ===========================================================================
variable "enable_replication" {
  description = "Enable ECR cross-region or cross-account replication."
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "Replication destinations: {region, registry_id}."
  type = list(object({
    region      = string
    registry_id = string
  }))
  default = []
}

variable "replication_repository_filters" {
  description = "Optional prefix filters for replication (empty = replicate all)."
  type        = list(string)
  default     = []
}

# ===========================================================================
# PULL-THROUGH CACHE
# ===========================================================================
variable "pull_through_cache_rules" {
  description = "Pull-through cache rules (upstream registry prefix → ECR namespace prefix)."
  type = map(object({
    upstream_registry_url = string
    credential_arn        = optional(string, null)
  }))
  default = {}
}
