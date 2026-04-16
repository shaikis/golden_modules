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
# AMI
# ---------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID. If empty, the latest Amazon Linux 2023 AMI is used."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Instance
# ---------------------------------------------------------------------------
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = null
}

variable "subnet_id" {
  type = string
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = []

  validation {
    condition     = length(var.vpc_security_group_ids) > 0
    error_message = "At least one security group ID must be provided."
  }
}

variable "iam_instance_profile" {
  type    = string
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

variable "user_data_base64" {
  type    = string
  default = null
}

variable "user_data_replace_on_change" {
  type    = bool
  default = false
}

variable "availability_zone" {
  type    = string
  default = null
}

variable "tenancy" {
  type    = string
  default = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "tenancy must be one of: default, dedicated, host."
  }
}

variable "instance_initiated_shutdown_behavior" {
  type    = string
  default = "stop"

  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "instance_initiated_shutdown_behavior must be stop or terminate."
  }
}

variable "disable_api_termination" {
  description = "Protect instance from accidental termination."
  type        = bool
  default     = true
}

variable "disable_api_stop" {
  description = "Protect instance from accidental stop."
  type        = bool
  default     = false
}

variable "monitoring" {
  description = "Enable detailed (1-minute) CloudWatch monitoring."
  type        = bool
  default     = true
}

variable "source_dest_check" {
  description = "Disable for NAT instances."
  type        = bool
  default     = true
}

variable "get_password_data" {
  description = "Retrieve Windows password data."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Root Volume
# ---------------------------------------------------------------------------
variable "root_volume_type" {
  type    = string
  default = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], var.root_volume_type)
    error_message = "Unsupported root_volume_type."
  }
}

variable "root_volume_size" {
  type    = number
  default = 50

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB."
  }
}

variable "root_volume_iops" {
  type    = number
  default = null
}

variable "root_volume_throughput" {
  type    = number
  default = null
}

variable "root_volume_encrypted" {
  type    = bool
  default = true
}

variable "root_volume_kms_key_id" {
  type    = string
  default = null
}

variable "root_volume_delete_on_termination" {
  type    = bool
  default = true
}

# ---------------------------------------------------------------------------
# Additional EBS Volumes
# ---------------------------------------------------------------------------
variable "ebs_volumes" {
  description = "Map of additional EBS volumes."
  type = map(object({
    device_name           = string
    volume_type           = optional(string, "gp3")
    volume_size           = number
    iops                  = optional(number, null)
    throughput            = optional(number, null)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string, null)
    delete_on_termination = optional(bool, true)
    snapshot_id           = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.ebs_volumes) :
      can(regex("^/dev/sd[f-p]$", v.device_name))
    ])
    error_message = "Each ebs_volumes[*].device_name must be like /dev/sdf through /dev/sdp."
  }

  validation {
    condition = alltrue([
      for v in values(var.ebs_volumes) :
      v.volume_size >= 1
    ])
    error_message = "Each EBS volume must be at least 1 GiB."
  }

  validation {
    condition = alltrue([
      for v in values(var.ebs_volumes) :
      contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], v.volume_type)
    ])
    error_message = "Each EBS volume must use a supported volume_type."
  }

  validation {
    condition = alltrue([
      for v in values(var.ebs_volumes) :
      v.volume_type != "gp3" || (
        (v.iops == null || (v.iops >= 3000 && v.iops <= 16000)) &&
        (v.throughput == null || (v.throughput >= 125 && v.throughput <= 1000))
      )
    ])
    error_message = "For gp3 volumes, iops and throughput must be within supported ranges."
  }
}

# ---------------------------------------------------------------------------
# Network Interface
# ---------------------------------------------------------------------------
variable "associate_public_ip_address" {
  description = "Associate a public IPv4 address."
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Primary private IPv4 address."
  type        = string
  default     = null
}

variable "secondary_private_ips" {
  description = "Secondary private IP addresses."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Placement Group
# ---------------------------------------------------------------------------
variable "placement_group" {
  description = "Placement group name."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Spot
# ---------------------------------------------------------------------------
variable "use_spot" {
  description = "Launch as a Spot instance."
  type        = bool
  default     = false
}

variable "spot_price" {
  description = "Maximum price per hour for Spot instance."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# CPU Options
# ---------------------------------------------------------------------------
variable "cpu_options" {
  description = "CPU options for the instance."
  type = object({
    core_count       = number
    threads_per_core = number
  })
  default = null
}

variable "cpu_credits" {
  description = "T-instance CPU credit option: standard or unlimited."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Metadata Options
# ---------------------------------------------------------------------------
variable "metadata_options" {
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "enabled")
  })

  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_options.http_endpoint)
    error_message = "metadata_options.http_endpoint must be enabled or disabled."
  }

  validation {
    condition     = contains(["optional", "required"], var.metadata_options.http_tokens)
    error_message = "metadata_options.http_tokens must be optional or required."
  }
}

# ---------------------------------------------------------------------------
# Elastic IP
# ---------------------------------------------------------------------------
variable "create_eip" {
  description = "Create and associate an Elastic IP."
  type        = bool
  default     = false
}
