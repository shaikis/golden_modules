variable "primary_region" {
  type    = string
  default = "us-east-1"
}
variable "dr_region" {
  type    = string
  default = "us-west-2"
}
variable "name" {
  type    = string
  default = "aurora"
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

# Aurora PostgreSQL engine version
variable "engine_version" {
  type    = string
  default = "16.2"
}

variable "db_name" {
  type    = string
  default = "appdb"
}
variable "username" {
  type    = string
  default = "dbadmin"
}

variable "primary_kms_key_arn" {
  type    = string
  default = null
}
variable "dr_kms_key_arn" {
  type    = string
  default = null
}

# Primary network
variable "primary_subnet_group_name" {
  type    = string
  default = ""
}
variable "primary_security_group_ids" {
  description = "List of security group IDs in primary VPC (can include multiple)"
  type        = list(string)
  default     = []
}

# Primary instances
variable "primary_instance_count" {
  type    = number
  default = 2
}
variable "primary_instance_class" {
  type    = string
  default = "db.r6g.large"
}

# DR network
variable "dr_subnet_group_name" {
  description = "Subnet group in DR VPC"
  type        = string
  default     = null
}
variable "dr_security_group_ids" {
  description = "Security group IDs in DR VPC — MUST be from DR VPC (not primary VPC)"
  type        = list(string)
  default     = []
}

# DR instances
variable "dr_instance_count" {
  type    = number
  default = 1
}
variable "dr_instance_class" {
  type    = string
  default = "db.r6g.large"
}

# Backup
variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "backup_window" {
  type    = string
  default = "02:00-03:00"
}
variable "maintenance_window" {
  type    = string
  default = "Mon:03:00-Mon:04:00"
}
variable "skip_final_snapshot" {
  type    = bool
  default = false
}
variable "deletion_protection" {
  type    = bool
  default = true
}

# Monitoring
variable "monitoring_interval" {
  type    = number
  default = 60
}
variable "performance_insights_enabled" {
  type    = bool
  default = true
}
variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql"]
}

# Feature toggle
variable "create_secondary_region" {
  description = "Create secondary Aurora cluster in DR region for global database"
  type        = bool
  default     = false
}
