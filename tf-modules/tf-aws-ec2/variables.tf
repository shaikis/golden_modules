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

variable "instance_initiated_shutdown_behavior" {
  type    = string
  default = "stop"
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
  description = "EC2 Instance Metadata Service (IMDS) options."
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required") # IMDSv2 required
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

# ---------------------------------------------------------------------------
# Elastic IP
# ---------------------------------------------------------------------------
variable "create_eip" {
  description = "Create and associate an Elastic IP."
  type        = bool
  default     = false
}
