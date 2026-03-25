variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "app-server"
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

# AMI
variable "ami_id" {
  type    = string
  default = ""
}

# Instance
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "subnet_id" {
  type    = string
  default = ""
}
variable "vpc_id" {
  type    = string
  default = ""
}
variable "key_name" {
  type    = string
  default = null
}
variable "availability_zone" {
  type    = string
  default = null
}
variable "tenancy" {
  type    = string
  default = "default"
}
variable "placement_group" {
  type    = string
  default = null
}
variable "get_password_data" {
  type    = bool
  default = false
}
variable "instance_initiated_shutdown_behavior" {
  type    = string
  default = "stop"
}

# User data
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

# Network
variable "associate_public_ip_address" {
  type    = bool
  default = false
}
variable "private_ip" {
  type    = string
  default = null
}
variable "secondary_private_ips" {
  type    = list(string)
  default = []
}
variable "source_dest_check" {
  type    = bool
  default = true
}

# Protection
variable "disable_api_termination" {
  type    = bool
  default = true
}
variable "disable_api_stop" {
  type    = bool
  default = false
}
variable "monitoring" {
  type    = bool
  default = true
}

# Root volume
variable "root_volume_type" {
  type    = string
  default = "gp3"
}
variable "root_volume_size" {
  type    = number
  default = 20
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

# Additional EBS volumes
variable "ebs_volumes" {
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
}

# CPU
variable "cpu_credits" {
  type    = string
  default = null
}
variable "cpu_options" {
  type = object({
    core_count       = number
    threads_per_core = number
  })
  default = null
}

# Metadata
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
}

# Elastic IP
variable "create_eip" {
  type    = bool
  default = false
}

# Spot
variable "use_spot" {
  type    = bool
  default = false
}
variable "spot_price" {
  type    = string
  default = null
}
