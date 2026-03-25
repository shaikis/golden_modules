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
  default = {
} }

variable "internal" {
  type    = bool
  default = false
}
variable "load_balancer_type" {
  type    = string
  default = "application"
}
variable "vpc_id" {
  type = string
}
variable "subnets" {
  type = list(string)
}
variable "security_groups" {
  type    = list(string)
  default = []
}
variable "enable_deletion_protection" {
  type    = bool
  default = true
}
variable "enable_http2" {
  type    = bool
  default = true
}
variable "enable_cross_zone_load_balancing" {
  type    = bool
  default = true
}
variable "idle_timeout" {
  type    = number
  default = 60
}
variable "drop_invalid_header_fields" {
  type    = bool
  default = true
}
variable "preserve_host_header" {
  type    = bool
  default = false
}
variable "ip_address_type" {
  type    = string
  default = "ipv4"
}

# Access Logs
variable "access_logs_bucket" {
  type    = string
  default = ""
}
variable "access_logs_prefix" {
  type    = string
  default = ""
}
variable "access_logs_enabled" {
  type    = bool
  default = false
}

# WAF
variable "web_acl_arn" {
  type    = string
  default = null
}

# Target Groups
variable "target_groups" {
  description = "Map of target group configurations."
  type = map(object({
    port             = number
    protocol         = optional(string, "HTTP")
    protocol_version = optional(string, "HTTP1")
    target_type      = optional(string, "instance")
    vpc_id           = optional(string, null)

    health_check = optional(object({
      enabled             = optional(bool, true)
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      matcher             = optional(string, "200-299")
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
    }), {})

    stickiness = optional(object({
      enabled         = optional(bool, false)
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
    }), null)

    deregistration_delay = optional(number, 300)
  }))
  default = {}
}

# Listeners
variable "listeners" {
  description = "Map of listener configurations."
  type = map(object({
    port              = number
    protocol          = optional(string, "HTTP")
    ssl_policy        = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    certificate_arn   = optional(string, null)
    default_action    = object({
      type             = string                      # forward, redirect, fixed-response
      target_group_key = optional(string, null)      # key from target_groups map
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
        host        = optional(string, null)
        path        = optional(string, null)
        query       = optional(string, null)
      }), null)
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string, null)
        status_code  = optional(string, "200")
      }), null)
    })
    additional_certificate_arns = optional(list(string), [])
  }))
  default = {}
}
