variable "region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "shared"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = "myproject"
}
variable "owner" {
  type    = string
  default = "platform"
}
variable "cost_center" {
  type    = string
  default = "shared"
}
variable "tags" {
  type    = map(string)
  default = {
} }

# Toggles
variable "create" {
  type    = bool
  default = true
}
variable "create_security_group" {
  type    = bool
  default = true
}
variable "enable_lifecycle_policy" {
  type    = bool
  default = true
}
variable "enable_backup_policy" {
  type    = bool
  default = true
}
variable "enable_replication" {
  type    = bool
  default = false
}

# Core
variable "encrypted" {
  type    = bool
  default = true
}
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "performance_mode" {
  type    = string
  default = "generalPurpose"
}
variable "throughput_mode" {
  type    = string
  default = "elastic"
}
variable "provisioned_throughput_in_mibps" {
  type    = number
  default = null
}

# Lifecycle
variable "transition_to_ia" {
  type    = string
  default = "AFTER_30_DAYS"
}
variable "transition_to_primary_storage_class" {
  type    = string
  default = "AFTER_1_ACCESS"
}

# Network
variable "vpc_id" {
  type    = string
  default = ""
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}
variable "allowed_security_group_ids" {
  type    = list(string)
  default = []
}

# Replication
variable "replication_destination_region" {
  type    = string
  default = null
}
variable "replication_destination_kms_key_arn" {
  type    = string
  default = null
}
variable "replication_destination_availability_zone" {
  type    = string
  default = null
}
