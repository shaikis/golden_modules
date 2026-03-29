variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "my-app"
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
} 

}

variable "vpc_id" {
  type    = string
  default = ""
}
variable "subnets" {
  type    = list(string)
  default = []
}
variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "target_groups" {
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
  default = {
    web = { port = 80 }
  }
}

variable "listeners" {
  type = map(object({
    port            = number
    protocol        = optional(string, "HTTP")
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    certificate_arn = optional(string, null)
    default_action = object({
      type             = string
      target_group_key = optional(string, null)
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
  default = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = { type = "forward"; target_group_key = "web" }
    }
  }
}
