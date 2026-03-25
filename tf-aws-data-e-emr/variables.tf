variable "create_serverless_applications" {
  description = "Whether to create EMR Serverless applications."
  type        = bool
  default     = false
}

variable "create_security_configurations" {
  description = "Whether to create EMR security configurations."
  type        = bool
  default     = false
}

variable "create_studios" {
  description = "Whether to create EMR Studio resources."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for EMR clusters."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Whether to create IAM roles for EMR (service role, instance profile, autoscaling role)."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of an existing KMS key for encryption. If null and create_security_configurations is true, encryption uses SSE-S3."
  type        = string
  default     = null
}

variable "role_arn" {
  description = "ARN of an existing IAM service role for EMR. Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "instance_profile_arn" {
  description = "ARN of an existing EC2 instance profile for EMR nodes. Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic to send CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "tags" {
  description = "Default tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "clusters" {
  description = "Map of EMR cluster configurations."
  type = map(object({
    release_label                     = optional(string, "emr-7.0.0")
    applications                      = optional(list(string), ["Spark", "Hadoop"])
    log_uri                           = optional(string, null)
    subnet_id                         = optional(string, null)
    key_name                          = optional(string, null)
    additional_master_security_groups = optional(list(string), [])
    additional_slave_security_groups  = optional(list(string), [])
    master_instance_type              = optional(string, "m5.xlarge")
    core_instance_type                = optional(string, "m5.xlarge")
    core_instance_count               = optional(number, 2)
    core_ebs_size                     = optional(number, 32)
    core_ebs_type                     = optional(string, "gp3")
    use_spot_for_core                 = optional(bool, false)
    core_bid_price                    = optional(string, null)
    keep_alive                        = optional(bool, true)
    termination_protection            = optional(bool, false)
    idle_timeout_seconds              = optional(number, 14400)
    security_configuration            = optional(string, null)
    configurations_json               = optional(string, null)
    bootstrap_actions = optional(list(object({
      name = string
      path = string
      args = optional(list(string), [])
    })), [])
    steps = optional(list(object({
      name              = string
      action_on_failure = optional(string, "CONTINUE")
      hadoop_jar        = string
      hadoop_jar_args   = optional(list(string), [])
      main_class        = optional(string, null)
      properties        = optional(map(string), {})
    })), [])
    task_instance_type          = optional(string, null)
    task_instance_count         = optional(number, 0)
    task_bid_price              = optional(string, null)
    kerberos_realm              = optional(string, null)
    kerberos_kdc_admin_password = optional(string, null)
    tags                        = optional(map(string), {})
  }))
  default = {}
}

variable "serverless_applications" {
  description = "Map of EMR Serverless application configurations."
  type = map(object({
    type                 = optional(string, "SPARK")
    release_label        = optional(string, "emr-7.0.0")
    max_cpu              = optional(string, "400vCPU")
    max_memory           = optional(string, "3000GB")
    max_disk             = optional(string, "20000GB")
    subnet_ids           = optional(list(string), [])
    security_group_ids   = optional(list(string), [])
    auto_start           = optional(bool, true)
    auto_stop            = optional(bool, true)
    idle_timeout_minutes = optional(number, 15)
    image_uri            = optional(string, null)
    initial_capacity = optional(map(object({
      worker_count  = number
      worker_cpu    = optional(string, "4vCPU")
      worker_memory = optional(string, "16GB")
      worker_disk   = optional(string, "200GB")
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "security_configurations" {
  description = "Map of EMR security configuration definitions."
  type = map(object({
    enable_s3_encryption                          = optional(bool, true)
    enable_local_disk_encryption                  = optional(bool, false)
    enable_in_transit_encryption                  = optional(bool, false)
    enable_kerberos                               = optional(bool, false)
    enable_lake_formation                         = optional(bool, false)
    kms_key_arn                                   = optional(string, null)
    certificate_provider_class                    = optional(string, null)
    certificate_provider_arg                      = optional(string, null)
    kerberos_realm                                = optional(string, null)
    kerberos_kdc_admin_password                   = optional(string, null)
    kerberos_cross_realm_trust_principal_password = optional(string, null)
    kerberos_ad_domain_join_password              = optional(string, null)
    kerberos_ad_domain_join_user                  = optional(string, null)
    kerberos_cross_realm_trust_realm              = optional(string, null)
    kerberos_cross_realm_trust_kdc                = optional(string, null)
  }))
  default = {}
}

variable "studios" {
  description = "Map of EMR Studio configurations."
  type = map(object({
    auth_mode                      = optional(string, "IAM")
    vpc_id                         = string
    subnet_ids                     = list(string)
    workspace_security_group_id    = string
    engine_security_group_id       = string
    s3_url                         = string
    service_role_arn               = optional(string, null)
    user_role_arn                  = optional(string, null)
    idp_auth_url                   = optional(string, null)
    idp_relay_state_parameter_name = optional(string, null)
    tags                           = optional(map(string), {})
  }))
  default = {}
}

variable "alarm_thresholds" {
  description = "Thresholds for CloudWatch alarms."
  type = object({
    hdfs_utilization_percent  = optional(number, 80)
    live_data_nodes_min       = optional(number, 1)
    core_nodes_min            = optional(number, 1)
    capacity_remaining_gb_min = optional(number, 100)
  })
  default = {}
}
