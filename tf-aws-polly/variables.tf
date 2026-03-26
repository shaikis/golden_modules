# ── Feature Gates ──────────────────────────────────────────────
variable "create_lexicons" {
  description = "Set true to create Polly pronunciation lexicons."
  type        = bool
  default     = false
}
variable "create_iam_role" {
  description = "Auto-create IAM role for Polly access. Set false to BYO role_arn."
  type        = bool
  default     = true
}

# ── BYO Pattern ────────────────────────────────────────────────
variable "role_arn" {
  description = "Existing IAM role ARN from tf-aws-iam. Used when create_iam_role = false."
  type        = string
  default     = null
}

# ── Global ─────────────────────────────────────────────────────
variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default     = ""
}
variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ── Lexicons ───────────────────────────────────────────────────
variable "lexicons" {
  description = "Map of Polly lexicons to create. Key = lexicon name."
  type = map(object({
    content = string # PLS XML content string
  }))
  default = {}
}

# ── IAM ────────────────────────────────────────────────────────
variable "enable_s3_output" {
  description = "Grant IAM role write access to an S3 bucket for storing Polly audio output."
  type        = bool
  default     = false
}
variable "s3_output_bucket_arn" {
  description = "ARN of the S3 bucket where Polly audio output will be stored. Required when enable_s3_output = true."
  type        = string
  default     = null
}
