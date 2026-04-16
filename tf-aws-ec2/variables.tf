variable "name_prefix" {
  description = "Optional prefix added to each instance name."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project tag."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Global tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "ami_id" {
  description = "AMI ID. If empty, the latest Amazon Linux 2023 AMI is used."
  type        = string
  default     = ""
}

variable "instances" {
  description = "Map of EC2 instances. Each key becomes one instance."
  type = map(object({
    name                          = optional(string)
    instance_type                 = optional(string, "t3.micro")
    key_name                      = optional(string, null)
    subnet_id                     = string
    vpc_security_group_ids        = list(string)
    iam_instance_profile          = optional(string, null)

    user_data                     = optional(string, null)
    user_data_base64              = optional(string, null)
    user_data_replace_on_change   = optional(bool, false)

    availability_zone             = optional(string, null)
    tenancy                       = optional(string, "default")
    instance_initiated_shutdown_behavior = optional(string, "stop")
    disable_api_termination       = optional(bool, true)
    disable_api_stop              = optional(bool, false)
    monitoring                    = optional(bool, true)
    source_dest_check             = optional(bool, true)
    get_password_data             = optional(bool, false)
    placement_group               = optional(string, null)

    associate_public_ip_address   = optional(bool, false)
    private_ip                    = optional(string, null)
    secondary_private_ips         = optional(list(string), [])

    root_volume_type              = optional(string, "gp3")
    root_volume_size              = optional(number, 50)
    root_volume_iops              = optional(number, null)
    root_volume_throughput        = optional(number, null)
    root_volume_encrypted         = optional(bool, true)
    root_volume_kms_key_id        = optional(string, null)
    root_volume_delete_on_termination = optional(bool, true)

    ebs_volumes = optional(map(object({
      device_name           = string
      volume_type           = optional(string, "gp3")
      volume_size           = number
      iops                  = optional(number, null)
      throughput            = optional(number, null)
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string, null)
      delete_on_termination = optional(bool, true)
      snapshot_id           = optional(string, null)
    })), {})

    use_spot                = optional(bool, false)
    spot_price              = optional(string, null)

    cpu_options = optional(object({
      core_count       = number
      threads_per_core = number
    }), null)

    cpu_credits = optional(string, null)

    metadata_options = optional(object({
      http_endpoint               = optional(string, "enabled")
      http_tokens                 = optional(string, "required")
      http_put_response_hop_limit = optional(number, 1)
      instance_metadata_tags      = optional(string, "enabled")
    }), {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "enabled"
    })

    create_eip = optional(bool, false)
    tags       = optional(map(string), {})
  }))

  validation {
    condition     = length(var.instances) > 0
    error_message = "At least one instance definition must be provided in var.instances."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) : length(inst.vpc_security_group_ids) > 0
    ])
    error_message = "Each instance must have at least one security group ID."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      contains(["default", "dedicated", "host"], inst.tenancy)
    ])
    error_message = "tenancy must be one of: default, dedicated, host."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      contains(["stop", "terminate"], inst.instance_initiated_shutdown_behavior)
    ])
    error_message = "instance_initiated_shutdown_behavior must be stop or terminate."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], inst.root_volume_type)
    ])
    error_message = "Unsupported root_volume_type."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) : inst.root_volume_size >= 8
    ])
    error_message = "root_volume_size must be at least 8 GiB."
  }

  validation {
    condition = alltrue(flatten([
      for inst in values(var.instances) : [
        for vol in values(inst.ebs_volumes) :
        can(regex("^/dev/sd[f-p]$", vol.device_name))
      ]
    ]))
    error_message = "Each ebs_volumes[*].device_name must be like /dev/sdf through /dev/sdp."
  }

  validation {
    condition = alltrue(flatten([
      for inst in values(var.instances) : [
        for vol in values(inst.ebs_volumes) : vol.volume_size >= 1
      ]
    ]))
    error_message = "Each EBS volume must be at least 1 GiB."
  }

  validation {
    condition = alltrue(flatten([
      for inst in values(var.instances) : [
        for vol in values(inst.ebs_volumes) :
        contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], vol.volume_type)
      ]
    ]))
    error_message = "Each EBS volume must use a supported volume_type."
  }

  validation {
    condition = alltrue(flatten([
      for inst in values(var.instances) : [
        for vol in values(inst.ebs_volumes) :
        vol.volume_type != "gp3" || (
          (vol.iops == null || (vol.iops >= 3000 && vol.iops <= 16000)) &&
          (vol.throughput == null || (vol.throughput >= 125 && vol.throughput <= 1000))
        )
      ]
    ]))
    error_message = "For gp3 volumes, iops and throughput must be within supported ranges."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      contains(["enabled", "disabled"], inst.metadata_options.http_endpoint)
    ])
    error_message = "metadata_options.http_endpoint must be enabled or disabled."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      contains(["optional", "required"], inst.metadata_options.http_tokens)
    ])
    error_message = "metadata_options.http_tokens must be optional or required."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      inst.metadata_options.http_put_response_hop_limit >= 1 && inst.metadata_options.http_put_response_hop_limit <= 64
    ])
    error_message = "metadata_options.http_put_response_hop_limit must be between 1 and 64."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      contains(["enabled", "disabled"], inst.metadata_options.instance_metadata_tags)
    ])
    error_message = "metadata_options.instance_metadata_tags must be enabled or disabled."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      !(inst.use_spot && inst.create_eip)
    ])
    error_message = "create_eip is supported only for on-demand instances in this module."
  }

  validation {
    condition = alltrue([
      for inst in values(var.instances) :
      !inst.use_spot || (inst.spot_price == null || trim(inst.spot_price) != "")
    ])
    error_message = "spot_price, when set, must be a non-empty string."
  }
}
