variable "environment" {
  type = string
}

variable "prefix_lists" {
  type = map(object({
    name           = string
    address_family = optional(string, "IPv4")
    max_entries    = number
    entries = map(object({
      cidr        = string
      description = optional(string)
    }))
    tags = optional(map(string), {})
  }))
}