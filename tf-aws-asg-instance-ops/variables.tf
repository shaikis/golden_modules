variable "asg_name" {
  type = string
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

# ===========================================================================
# SCALE-IN PROTECTION (per instance)
# ===========================================================================
variable "protected_instance_ids" {
  description = "Instance IDs to protect from scale-in termination."
  type        = list(string)
  default     = []
}

# ===========================================================================
# STANDBY (detach from load balancer + health checks, keep in ASG)
# ===========================================================================
variable "standby_instance_ids" {
  description = "Instance IDs to put into Standby (for patching, debugging)."
  type        = list(string)
  default     = []
}

variable "standby_should_decrement_desired" {
  description = "Decrement desired capacity when moving to standby."
  type        = bool
  default     = true
}

# ===========================================================================
# DETACH (remove from ASG, optionally terminate)
# ===========================================================================
variable "detach_instance_ids" {
  description = "Instance IDs to detach from the ASG."
  type        = list(string)
  default     = []
}

variable "detach_should_decrement_desired" {
  description = "Decrement desired capacity when detaching instances."
  type        = bool
  default     = true
}
