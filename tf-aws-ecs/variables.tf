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
  default = {}
}

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------
variable "container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for cluster encryption."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Capacity Providers
# ---------------------------------------------------------------------------
variable "use_fargate" {
  type    = bool
  default = true
}
variable "use_ec2" {
  type    = bool
  default = false
}
variable "use_fargate_spot" {
  type    = bool
  default = false
}

# ---------------------------------------------------------------------------
# Task Definitions
# ---------------------------------------------------------------------------
variable "task_definitions" {
  description = "Map of ECS task definitions."
  type = map(object({
    cpu                      = number
    memory                   = number
    network_mode             = optional(string, "awsvpc")
    requires_compatibilities = optional(list(string), ["FARGATE"])
    execution_role_arn       = optional(string, null) # null = auto-create
    task_role_arn            = optional(string, null)
    container_definitions    = string # JSON string of container definitions

    volumes = optional(list(object({
      name      = string
      host_path = optional(string, null)
      efs_volume_configuration = optional(object({
        file_system_id          = string
        root_directory          = optional(string, "/")
        transit_encryption      = optional(string, "ENABLED")
        transit_encryption_port = optional(number, null)
        authorization_config = optional(object({
          access_point_id = optional(string, null)
          iam             = optional(string, "ENABLED")
        }), null)
      }), null)
    })), [])

    runtime_platform = optional(object({
      operating_system_family = optional(string, "LINUX")
      cpu_architecture        = optional(string, "X86_64")
    }), null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------
variable "services" {
  description = "Map of ECS services."
  type = map(object({
    task_definition_key    = string
    desired_count          = optional(number, 1)
    launch_type            = optional(string, "FARGATE")
    platform_version       = optional(string, "LATEST")
    propagate_tags         = optional(string, "SERVICE")
    enable_execute_command = optional(bool, false)

    network_configuration = object({
      subnets          = list(string)
      security_groups  = optional(list(string), [])
      assign_public_ip = optional(bool, false)
    })

    load_balancers = optional(list(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    })), [])

    service_registries = optional(list(object({
      registry_arn   = string
      port           = optional(number, null)
      container_name = optional(string, null)
      container_port = optional(number, null)
    })), [])

    deployment_circuit_breaker = optional(object({
      enable   = bool
      rollback = bool
    }), { enable = true, rollback = true })

    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_maximum_percent         = optional(number, 200)

    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      weight            = number
      base              = optional(number, 0)
    })), [])
  }))
  default = {}
}
