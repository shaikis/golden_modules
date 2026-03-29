# =============================================================================
# EXAMPLE: ALB → IP Targets
#
# Three patterns on one ALB:
#   /api/*      → ECS Fargate containers  (ip target, ECS registers IPs itself)
#   /legacy/*   → on-premises servers     (ip target, static IPs via VPN/DX)
#   /internal/* → cross-VPC peered IPs    (ip target, static IPs in peered VPC)
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

# ── ALB ───────────────────────────────────────────────────────────────────────
module "alb" {
  source = "../../"

  name        = var.name
  environment = var.environment
  vpc_id      = var.vpc_id
  subnets     = var.public_subnet_ids

  create_security_group      = true
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  target_groups = {
    # Pattern A: ECS Fargate — no attachments; ECS registers container IPs
    fargate = {
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
      health_check = { path = "/health", interval = 15, matcher = "200" }
    }

    # Pattern B: On-premises static IPs over VPN/Direct Connect
    # availability_zone = "all" is required for IPs outside the VPC
    onprem = {
      port        = 80
      protocol    = "HTTP"
      target_type = "ip"
      health_check = { path = "/ping", interval = 30, timeout = 10, matcher = "200-299" }
      attachments = [
        for ip in var.onprem_server_ips : {
          target_id         = ip
          port              = 80
          availability_zone = "all"
        }
      ]
    }

    # Pattern C: Cross-VPC peered service (IPs within a peered VPC CIDR)
    peered = {
      port        = 9090
      protocol    = "HTTP"
      target_type = "ip"
      health_check = { path = "/healthz", port = "9090", interval = 20, matcher = "200" }
      attachments = [
        for ip in var.peered_service_ips : { target_id = ip, port = 9090 }
      ]
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
      default_action  = { type = "forward", target_group_key = "fargate" }
      rules = [
        { priority = 10, conditions = [{ path_pattern = ["/api/*", "/v1/*"] }],      action = { type = "forward", target_group_key = "fargate" } },
        { priority = 20, conditions = [{ path_pattern = ["/legacy/*", "/classic/*"] }], action = { type = "forward", target_group_key = "onprem" } },
        { priority = 30, conditions = [{ path_pattern = ["/internal/*"] }],          action = { type = "forward", target_group_key = "peered" } }
      ]
    }
  }
}

# ── Fargate task SG (allow inbound from ALB only) ─────────────────────────────
resource "aws_security_group" "fargate" {
  name        = "${var.name}-fargate"
  description = "Fargate tasks: inbound from ALB only"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-fargate" }
}

resource "aws_vpc_security_group_ingress_rule" "fargate_from_alb" {
  security_group_id            = aws_security_group.fargate.id
  referenced_security_group_id = module.alb.security_group_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "fargate_all" {
  security_group_id = aws_security_group.fargate.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── ECS Fargate (Pattern A) — registers container IPs with ALB TG ─────────────
resource "aws_ecs_cluster" "this" {
  name = var.name
  setting { name = "containerInsights"; value = "enabled" }
}

resource "aws_iam_role" "ecs_exec" {
  name               = "${var.name}-ecs-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_exec.arn
  container_definitions = jsonencode([{
    name      = "api"
    image     = var.api_container_image
    essential = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options   = { "awslogs-group" = "/ecs/${var.name}/api", "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "api", "awslogs-create-group" = "true" }
    }
  }])
}

resource "aws_ecs_service" "api" {
  name            = "${var.name}-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.fargate_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.fargate.id]
    assign_public_ip = false
  }

  # This line is what registers/deregisters Fargate container IPs with the TG
  load_balancer {
    target_group_arn = module.alb.target_group_arns["fargate"]
    container_name   = "api"
    container_port   = 8080
  }

  deployment_circuit_breaker { enable = true; rollback = true }
  depends_on = [module.alb]
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "alb_dns_name"     { value = module.alb.lb_dns_name }
output "ecs_service_name" { value = aws_ecs_service.api.name }
