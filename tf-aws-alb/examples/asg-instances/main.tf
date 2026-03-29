# =============================================================================
# EXAMPLE: ALB → Auto Scaling Group
#
# HTTP:80  → redirect to HTTPS
# HTTPS:443 → ASG instances (web:80, api:8080)
#   /health   → fixed 200 (no backend round-trip)
#   /api/*    → api target group
#   /*        → web target group (default)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = var.name
  tags = {
    Environment = var.environment
  }

  keys = {
    asg = {
      description = "KMS key for ${var.name} ASG instances behind ALB"
    }
  }
}

# ── ALB ───────────────────────────────────────────────────────────────────────
module "alb" {
  source = "../../"

  name        = var.name
  environment = var.environment
  vpc_id      = var.vpc_id
  subnets     = var.public_subnet_ids

  create_security_group      = true # module creates HTTP/HTTPS SG, outputs security_group_id
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  target_groups = {
    web = {
      port         = 80
      protocol     = "HTTP"
      target_type  = "instance"
      slow_start   = 60
      health_check = { path = "/health", interval = 15, matcher = "200" }
      stickiness   = { enabled = true, type = "lb_cookie", cookie_duration = 3600 }
    }
    api = {
      port                          = 8080
      protocol                      = "HTTP"
      target_type                   = "instance"
      deregistration_delay          = 60
      load_balancing_algorithm_type = "least_outstanding_requests"
      health_check                  = { path = "/api/health", port = "8080", interval = 10, matcher = "200" }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type     = "redirect"
        redirect = { port = "443", protocol = "HTTPS", status_code = "HTTP_301" }
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn
      default_action  = { type = "forward", target_group_key = "web" }
      rules = [
        {
          priority   = 10
          conditions = [{ path_pattern = ["/health"] }]
          action     = { type = "fixed-response", fixed_response = { content_type = "application/json", message_body = "{\"status\":\"ok\"}", status_code = "200" } }
        },
        {
          priority   = 20
          conditions = [{ path_pattern = ["/api/*", "/v1/*", "/v2/*"] }]
          action     = { type = "forward", target_group_key = "api" }
        }
      ]
    }
  }
}

# ── Instance security group (allows traffic only from ALB) ───────────────────
resource "aws_security_group" "instance" {
  name        = "${var.name}-instance"
  description = "EC2 instances: inbound from ALB only"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-instance" }
}

resource "aws_vpc_security_group_ingress_rule" "http_from_alb" {
  security_group_id            = aws_security_group.instance.id
  referenced_security_group_id = module.alb.security_group_id
  from_port                    = 80
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "HTTP/API from ALB"
}

resource "aws_vpc_security_group_egress_rule" "instance_all" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── ASG (uses tf-aws-asg module — handles LT, AMI lookup, scaling policies) ──
module "asg" {
  source = "../../../tf-aws-asg"

  name        = var.name
  environment = var.environment

  vpc_zone_identifier = var.private_subnet_ids
  security_group_ids  = [aws_security_group.instance.id]
  instance_type       = var.instance_type
  key_name            = var.key_name
  kms_key_arn         = module.kms.key_arns["asg"]
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 120

  # Attach to both ALB target groups — the module creates one
  # aws_autoscaling_attachment per ARN, so adding/removing a TG here
  # will register/deregister all ASG instances on the next apply.
  target_group_arns = values(module.alb.target_group_arns)

  # CPU + ALB request count target tracking (built into the module)
  enable_cpu_scaling          = true
  cpu_target_value            = 60
  enable_alb_request_scaling  = true
  alb_request_target_value    = 1000
  alb_target_group_arn_suffix = module.alb.target_group_arn_suffixes["web"]
  alb_arn_suffix              = module.alb.lb_arn_suffix
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "alb_dns_name" { value = module.alb.lb_dns_name }
output "asg_name" { value = module.asg.asg_name }
