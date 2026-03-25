variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "entries_list" {
  description = "List of CIDRs"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.entries_list :
      can(cidrnetmask(trim(cidr)))
    ])
    error_message = "All entries must be valid CIDRs."
  }
}

variable "address_family" {
  type    = string
  default = "IPv4"

  validation {
    condition     = contains(["IPv4", "IPv6"], var.address_family)
    error_message = "Must be IPv4 or IPv6."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "allow_replacement" {
  type    = bool
  default = false
}