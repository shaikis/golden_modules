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

# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------
variable "engine" {
  description = "aurora-mysql or aurora-postgresql"
  type        = string
  default     = "aurora-postgresql"

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.engine)
    error_message = "engine must be aurora-mysql or aurora-postgresql."
  }
}

variable "engine_version" {
  description = "Aurora engine version (e.g. 15.4 for aurora-postgresql, 8.0.mysql_aurora.3.04.0 for aurora-mysql)."
  type        = string
  default     = "15.4"
}

variable "engine_mode" {
  description = "provisioned or serverless (serverless = Aurora Serverless v1, legacy)."
  type        = string
  default     = "provisioned"
}

variable "cluster_members" {
  description = "Pre-existing cluster member instance IDs (for global cluster attachment)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Serverless v2 Scaling (engine_mode = provisioned + db.serverless instance class)
# ---------------------------------------------------------------------------
variable "serverlessv2_scaling" {
  description = "Enable Aurora Serverless v2. Provide min/max ACU."
  type = list(object({
    min_capacity = number
    max_capacity = number
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
variable "database_name" {
  type    = string
  default = null
}
variable "master_username" {
  type    = string
  default = "clusteradmin"
}
variable "master_password" {
  type      = string
  default   = null
  sensitive = true
}
variable "manage_master_user_password" {
  type    = bool
  default = true
}
variable "master_user_secret_kms_key_id" {
  type    = string
  default = null
}
variable "port" {
  type    = number
  default = null
}

# ---------------------------------------------------------------------------
# Instances
# ---------------------------------------------------------------------------
variable "instance_class" {
  description = "DB instance class. Use db.serverless for Serverless v2."
  type        = string
  default     = "db.t3.medium"
}

variable "cluster_instances" {
  description = "Map of Aurora cluster instances. Key = instance suffix."
  type = map(object({
    instance_class              = optional(string, null)  # overrides cluster default
    publicly_accessible         = optional(bool, false)
    availability_zone           = optional(string, null)
    auto_minor_version_upgrade  = optional(bool, true)
    performance_insights_enabled = optional(bool, true)
    monitoring_interval          = optional(number, 60)
    promotion_tier               = optional(number, 0)
    preferred_maintenance_window = optional(string, null)
  }))
  default = {
    "1" = {}  # writer
    "2" = {}  # reader
  }
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "db_subnet_group_name" {
  type = string
}
variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
variable "availability_zones" {
  type    = list(string)
  default = []
}
variable "network_type" {
  type    = string
  default = "IPV4"
}

# ---------------------------------------------------------------------------
# Encryption
# ---------------------------------------------------------------------------
variable "storage_encrypted" {
  type    = bool
  default = true
}
variable "kms_key_id" {
  type    = string
  default = null
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
variable "backup_retention_period" {
  type    = number
  default = 14
}
variable "preferred_backup_window" {
  type    = string
  default = "02:00-03:00"
}
variable "preferred_maintenance_window" {
  type    = string
  default = "sun:05:00-sun:06:00"
}
variable "skip_final_snapshot" {
  type    = bool
  default = false
}
variable "final_snapshot_identifier_prefix" {
  type    = string
  default = "final"
}
variable "copy_tags_to_snapshot" {
  type    = bool
  default = true
}
variable "backtrack_window" {
  type    = number
  default = 0
}  # aurora-mysql only

# ---------------------------------------------------------------------------
# Protection
# ---------------------------------------------------------------------------
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "apply_immediately" {
  type    = bool
  default = false
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
variable "monitoring_interval" {
  type    = number
  default = 60
}
variable "create_monitoring_role" {
  type    = bool
  default = true
}
variable "monitoring_role_arn" {
  type    = string
  default = null
}
variable "performance_insights_enabled" {
  type    = bool
  default = true
}
variable "performance_insights_kms_key_id" {
  type    = string
  default = null
}
variable "performance_insights_retention_period" {
  type    = number
  default = 7
}
variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql"]
}

# ---------------------------------------------------------------------------
# Parameter Groups
# ---------------------------------------------------------------------------
variable "cluster_parameter_group_name" {
  type    = string
  default = null
}
variable "instance_parameter_group_name" {
  type    = string
  default = null
}
variable "create_cluster_parameter_group" {
  type    = bool
  default = false
}
variable "cluster_parameter_group_family" {
  type    = string
  default = "aurora-postgresql15"
}
variable "cluster_parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Global Cluster
# ---------------------------------------------------------------------------
variable "global_cluster_identifier" {
  description = "ARN of an existing global cluster to join. Leave empty to create standalone cluster."
  type        = string
  default     = null
}

variable "create_global_cluster" {
  description = "Create a new Aurora Global Cluster."
  type        = bool
  default     = false
}

variable "global_cluster_engine" {
  type    = string
  default = null
}
variable "global_cluster_engine_version" {
  type    = string
  default = null
}
variable "source_region" {
  type    = string
  default = null
}

# ---------------------------------------------------------------------------
# Auto Scaling (read replicas)
# ---------------------------------------------------------------------------
variable "autoscaling_enabled" {
  type    = bool
  default = false
}
variable "autoscaling_min_capacity" {
  type    = number
  default = 1
}
variable "autoscaling_max_capacity" {
  type    = number
  default = 5
}
variable "autoscaling_target_cpu" {
  type    = number
  default = 70
}
variable "autoscaling_scale_in_cooldown" {
  type    = number
  default = 300
}
variable "autoscaling_scale_out_cooldown" {
  type    = number
  default = 300
}
variable "autoscaling_policy_type" {
  type    = string
  default = "TargetTrackingScaling"
}
