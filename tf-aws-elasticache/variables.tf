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

variable "engine" {
  description = "redis or memcached."
  type        = string
  default     = "redis"

  validation {
    condition     = contains(["redis", "memcached"], var.engine)
    error_message = "engine must be redis or memcached."
  }
}

variable "engine_version" {
  type    = string
  default = "7.0"
}
variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}
variable "num_cache_nodes" {
  type    = number
  default = 1
}   # memcached
variable "port" {
  type    = number
  default = 6379
}

# Redis replication group
variable "automatic_failover_enabled" {
  type    = bool
  default = true
}
variable "multi_az_enabled" {
  type    = bool
  default = true
}
variable "num_cache_clusters" {
  type    = number
  default = 2
}   # primary + replicas
variable "num_node_groups" {
  type    = number
  default = 1
}   # shards
variable "replicas_per_node_group" {
  type    = number
  default = 1
}

variable "subnet_group_name" {
  type    = string
  default = null
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "availability_zones" {
  type    = list(string)
  default = []
}
variable "preferred_cache_cluster_azs" {
  type    = list(string)
  default = []
}

variable "at_rest_encryption_enabled" {
  type    = bool
  default = true
}
variable "transit_encryption_enabled" {
  type    = bool
  default = true
}
variable "auth_token" {
  type      = string
  default   = null
  sensitive = true
}
variable "kms_key_id" {
  type    = string
  default = null
}

variable "maintenance_window" {
  type    = string
  default = "sun:05:00-sun:06:00"
}
variable "snapshot_window" {
  type    = string
  default = "03:00-04:00"
}
variable "snapshot_retention_limit" {
  type    = number
  default = 7
}

variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}
variable "apply_immediately" {
  type    = bool
  default = false
}
variable "notification_topic_arn" {
  type    = string
  default = null
}

variable "parameter_group_family" {
  type    = string
  default = "redis7"
}

variable "parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "create_parameter_group" {
  type    = bool
  default = false
}
variable "log_delivery_configurations" {
  description = "Slow/engine log delivery configurations."
  type = list(object({
    destination      = string
    destination_type = string    # cloudwatch-logs or kinesis-firehose
    log_format       = string    # text or json
    log_type         = string    # slow-log or engine-log
  }))
  default = []
}
