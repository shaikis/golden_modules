variable "name" { type = string }
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
# Load Balancer
# ---------------------------------------------------------------------------
variable "internal" {
  description = "true = internal (VPC-only), false = internet-facing."
  type        = bool
  default     = false
}
variable "load_balancer_type" {
  description = "application | network | gateway."
  type        = string
  default     = "application"
}
variable "vpc_id" {
  description = "VPC ID. Required for target groups."
  type        = string
}
variable "subnets" {
  description = "Subnet IDs. At least 2 AZs for ALB."
  type        = list(string)
}
variable "security_groups" {
  description = "Security group IDs (ALB only; not used for NLB)."
  type        = list(string)
  default     = []
}
variable "enable_deletion_protection" {
  type    = bool
  default = true
}
variable "enable_http2" {
  description = "Enable HTTP/2 on ALB. Not applicable for NLB."
  type        = bool
  default     = true
}
variable "enable_cross_zone_load_balancing" {
  type    = bool
  default = true
}
variable "idle_timeout" {
  description = "Connection idle timeout in seconds (ALB only)."
  type        = number
  default     = 60
}
variable "drop_invalid_header_fields" {
  description = "Drop HTTP headers with invalid characters. Recommended true for security."
  type        = bool
  default     = true
}
variable "preserve_host_header" {
  description = "Forward the original Host header to targets unchanged."
  type        = bool
  default     = false
}
variable "ip_address_type" {
  description = "ipv4 | dualstack | dualstack-without-public-ipv4."
  type        = string
  default     = "ipv4"
}
variable "desync_mitigation_mode" {
  description = <<-EOT
    HTTP desync attack mitigation: monitor | defensive | strictest.
    - monitor    : log but allow desync requests
    - defensive  : block clearly malicious; allow ambiguous (default AWS)
    - strictest  : block all non-RFC-compliant requests (recommended for public ALBs)
  EOT
  type        = string
  default     = "defensive"
}
variable "xff_header_processing_mode" {
  description = <<-EOT
    X-Forwarded-For header handling: append | preserve | remove.
    - append   : ALB adds client IP to existing XFF header (default)
    - preserve : pass the header as-is (used behind another proxy)
    - remove   : strip the header (use when targets must not see client IP)
  EOT
  type        = string
  default     = "append"
}
variable "client_keep_alive" {
  description = "Duration in seconds for client keep-alive connections (ALB only). Range: 60–604800."
  type        = number
  default     = 3600
}

# ---------------------------------------------------------------------------
# Access Logs
# ---------------------------------------------------------------------------
variable "access_logs_enabled" {
  type    = bool
  default = false
}
variable "access_logs_bucket" {
  type    = string
  default = ""
}
variable "access_logs_prefix" {
  type    = string
  default = ""
}

# ---------------------------------------------------------------------------
# Connection Logs (ALB only — separate from access logs)
# ---------------------------------------------------------------------------
variable "connection_logs_enabled" {
  description = "Enable connection-level logs (TLS handshake metadata)."
  type        = bool
  default     = false
}
variable "connection_logs_bucket" {
  type    = string
  default = ""
}
variable "connection_logs_prefix" {
  type    = string
  default = ""
}

# ---------------------------------------------------------------------------
# Managed Security Group
# When create_security_group = true the module creates an ALB security group
# that allows HTTP (80) and HTTPS (443) inbound from the specified CIDRs
# and all outbound. Pass the output security_group_id to instance/ECS SGs.
# ---------------------------------------------------------------------------
variable "create_security_group" {
  description = "Create a managed security group for the ALB. When false, pass pre-existing SGs via security_groups."
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Name for the managed SG. Defaults to <name>-alb."
  type        = string
  default     = null
}

variable "security_group_ingress_cidr_ipv4" {
  description = "IPv4 CIDRs allowed to reach the ALB on HTTP/HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_ingress_cidr_ipv6" {
  description = "IPv6 CIDRs allowed to reach the ALB on HTTP/HTTPS."
  type        = list(string)
  default     = ["::/0"]
}

# ---------------------------------------------------------------------------
# WAF
# ---------------------------------------------------------------------------
variable "web_acl_arn" {
  type    = string
  default = null
}

# ---------------------------------------------------------------------------
# Target Groups
# ---------------------------------------------------------------------------
variable "target_groups" {
  description = "Map of target group configurations keyed by a logical name."
  type = map(object({
    port             = optional(number)             # null for Lambda targets
    protocol         = optional(string, "HTTP")     # HTTP | HTTPS | TCP | TLS | UDP | TCP_UDP | GENEVE
    protocol_version = optional(string, "HTTP1")    # HTTP1 | HTTP2 | GRPC (ALB only)
    target_type      = optional(string, "instance") # instance | ip | lambda | alb
    vpc_id           = optional(string, null)

    # Load balancing algorithm — ALB only
    # round_robin | least_outstanding_requests | weighted_random
    load_balancing_algorithm_type = optional(string, "round_robin")

    # Anomaly mitigation with weighted_random algorithm (ALB only)
    load_balancing_anomaly_mitigation = optional(string, "off") # off | on

    # Slow-start warm-up window in seconds (0 = disabled). Max 900.
    slow_start = optional(number, 0)

    # Connection draining timeout — how long to wait for in-flight requests
    deregistration_delay = optional(number, 300)

    # Lambda targets: pass multi-value headers as arrays
    lambda_multi_value_headers_enabled = optional(bool, false)

    # Keep-alive duration for target connections (ALB HTTP/HTTPS targets only, seconds)
    connection_termination = optional(bool, false)

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
      type            = optional(string, "lb_cookie") # lb_cookie | app_cookie | source_ip
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string, null) # required for app_cookie
    }), null)

    # Static targets to attach (instances, IPs, or Lambda ARNs)
    # Each: { target_id, port (optional), availability_zone (optional) }
    attachments = optional(list(object({
      target_id         = string
      port              = optional(number)
      availability_zone = optional(string)
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Listeners
# ---------------------------------------------------------------------------
variable "listeners" {
  description = "Map of listener configurations keyed by a logical name."
  type = map(object({
    port     = number
    protocol = optional(string, "HTTP") # HTTP | HTTPS | TCP | TLS | UDP | TCP_UDP

    # HTTPS/TLS only
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    certificate_arn = optional(string, null)

    # Mutual TLS (mTLS) — HTTPS listeners only
    # trust_store_arn: ARN of an aws_lb_trust_store resource
    # mode: off | passthrough | verify
    mutual_authentication = optional(object({
      mode                             = string
      trust_store_arn                  = optional(string, null)
      ignore_client_certificate_expiry = optional(bool, false)
    }), null)

    # ALPN policy for TLS listeners (NLB): HTTP1Only | HTTP2Only | HTTP2Optional |
    #                                      HTTP2Preferred | None
    alpn_policy = optional(string, null)

    default_action = object({
      type             = string # forward | redirect | fixed-response | authenticate-oidc | authenticate-cognito
      target_group_key = optional(string, null)

      # Weighted forward to multiple target groups
      forward = optional(object({
        target_groups = list(object({
          target_group_key = string
          weight           = optional(number, 1)
        }))
        stickiness = optional(object({
          enabled  = bool
          duration = optional(number, 86400)
        }), null)
      }), null)

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

    # Extra certificates for SNI (HTTPS listeners)
    additional_certificate_arns = optional(list(string), [])

    # Listener rules — evaluated in priority order before the default action
    rules = optional(list(object({
      priority = number

      # Conditions — all must match (AND logic)
      conditions = list(object({
        # Set exactly one of the following:
        path_pattern = optional(list(string), null) # e.g. ["/api/*", "/v2/*"]
        host_header  = optional(list(string), null) # e.g. ["api.example.com"]
        http_method  = optional(list(string), null) # e.g. ["GET", "POST"]
        source_ip    = optional(list(string), null) # CIDR blocks
        query_string = optional(list(object({       # key=value pairs
          key   = optional(string, null)
          value = string
        })), null)
        http_header = optional(object({
          header_name = string
          values      = list(string)
        }), null)
      }))

      # Action — what to do when conditions match
      action = object({
        type             = string # forward | redirect | fixed-response | authenticate-oidc | authenticate-cognito
        target_group_key = optional(string, null)

        forward = optional(object({
          target_groups = list(object({
            target_group_key = string
            weight           = optional(number, 1)
          }))
          stickiness = optional(object({
            enabled  = bool
            duration = optional(number, 86400)
          }), null)
        }), null)

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
    })), [])
  }))
  default = {}
}
