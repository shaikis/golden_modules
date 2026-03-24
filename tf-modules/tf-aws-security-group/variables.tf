variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
}
variable "description" {
  type    = string
  default = "Managed by Terraform"
}
variable "vpc_id" {
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
  type = map(string)
  default = {
  }
}

variable "ingress_rules" {
  description = "Map of ingress rules. Key = rule name."
  type = map(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    source_sg_ids    = optional(list(string), [])
    self             = optional(bool, false)
    description      = optional(string, "")
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of egress rules. Key = rule name. Default: allow all outbound."
  type = map(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    dest_sg_ids      = optional(list(string), [])
    self             = optional(bool, false)
    description      = optional(string, "")
  }))
  default = {
    all_outbound = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  }
}

variable "revoke_rules_on_delete" {
  description = "Revoke all rules before deleting the security group."
  type        = bool
  default     = true
}
