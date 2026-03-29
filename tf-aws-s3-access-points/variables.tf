variable "bucket" {
  description = "Name of the S3 bucket for which access points will be created."
  type        = string
}

variable "bucket_account_id" {
  description = "Optional account ID that owns the bucket."
  type        = string
  default     = null
}

variable "access_points" {
  description = "Access point definitions."
  type = list(object({
    name   = string
    policy = optional(string, null)
    vpc_id = optional(string, null)
    public_access_block_configuration = optional(object({
      block_public_acls       = optional(bool, true)
      block_public_policy     = optional(bool, true)
      ignore_public_acls      = optional(bool, true)
      restrict_public_buckets = optional(bool, true)
    }), null)
    tags = optional(map(string), {})
  }))
  default = []
}

variable "tags" {
  description = "Common tags applied to all access points."
  type        = map(string)
  default     = {}
}
