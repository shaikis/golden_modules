# =============================================================================
# EXAMPLE: ALB → Lambda Functions
#
# Three Lambda microservices behind one ALB:
#   /api/users/*    → lambda_users
#   /api/orders/*   → lambda_orders
#   /api/products/* → lambda_products
#   OPTIONS /*      → fixed 200 (CORS preflight, no Lambda invocation)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

provider "aws" { region = var.aws_region }

# ── Shared Lambda execution role ──────────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── Lambda functions (inline zip — replace with S3/ECR in production) ─────────
locals {
  services = toset(["users", "orders", "products"])
}

resource "local_file" "handler" {
  for_each = local.services
  filename = "${path.module}/.build/${each.key}/index.js"
  content  = <<-JS
    exports.handler = async (event) => ({
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ service: "${each.key}", path: event.path, method: event.httpMethod })
    });
  JS
}

data "archive_file" "lambda" {
  for_each    = local.services
  type        = "zip"
  source_file = local_file.handler[each.key].filename
  output_path = "${path.module}/.build/${each.key}.zip"
}

resource "aws_lambda_function" "this" {
  for_each = local.services

  function_name    = "${var.name}-${each.key}"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  timeout          = 30
  memory_size      = 256
  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256
  tracing_config   { mode = "Active" }
  tags             = { Name = "${var.name}-${each.key}" }
}

# ── ALB ───────────────────────────────────────────────────────────────────────
module "alb" {
  source = "../../"

  name        = var.name
  environment = var.environment
  vpc_id      = var.vpc_id
  subnets     = var.public_subnet_ids

  create_security_group      = true
  enable_deletion_protection = false

  target_groups = {
    for svc in local.services : svc => {
      target_type                        = "lambda"
      lambda_multi_value_headers_enabled = true
      health_check = { path = "/api/${svc}/health", interval = 35, timeout = 30, matcher = "200" }
      attachments  = [{ target_id = aws_lambda_function.this[svc].arn }]
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
      default_action  = { type = "forward", target_group_key = "users" }
      rules = [
        { priority = 1,  conditions = [{ http_method = ["OPTIONS"] }],                         action = { type = "fixed-response", fixed_response = { content_type = "text/plain", status_code = "200" } } },
        { priority = 10, conditions = [{ path_pattern = ["/api/users",    "/api/users/*"]    }], action = { type = "forward", target_group_key = "users"    } },
        { priority = 20, conditions = [{ path_pattern = ["/api/orders",   "/api/orders/*"]   }], action = { type = "forward", target_group_key = "orders"   } },
        { priority = 30, conditions = [{ path_pattern = ["/api/products", "/api/products/*"] }], action = { type = "forward", target_group_key = "products" } }
      ]
    }
  }

  depends_on = [aws_lambda_function.this]
}

# ── Lambda permissions — allow ALB to invoke each function ───────────────────
resource "aws_lambda_permission" "alb" {
  for_each = local.services

  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = module.alb.target_group_arns[each.key]
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "alb_dns_name"  { value = module.alb.lb_dns_name }
output "lambda_arns"   { value = { for k, fn in aws_lambda_function.this : k => fn.arn } }
