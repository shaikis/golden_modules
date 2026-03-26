# =============================================================================
# Game Development Pipeline — Outputs
# =============================================================================

# ---------------------------------------------------------------------------
# Perforce P4
# ---------------------------------------------------------------------------
output "p4_server_private_ip" {
  description = "Private IP address of the Perforce P4 Commit Server EC2 instance."
  value       = module.p4_server.private_ip
}

output "p4_connection_string" {
  description = "Perforce connection string — paste into P4V > Connection > Open Connection > Server."
  value       = "ssl:p4.${var.domain_name}:1666"
}

output "p4_nlb_dns_name" {
  description = "Network Load Balancer DNS name for direct Perforce TCP/1666 access (before DNS propagates)."
  value       = module.p4_nlb.lb_dns_name
}

output "p4_admin_secret_arn" {
  description = "Secrets Manager ARN containing Perforce admin credentials. Retrieve with: aws secretsmanager get-secret-value --secret-id <arn>."
  value       = module.secret_p4_admin.secret_arn
}

# ---------------------------------------------------------------------------
# Unreal Engine Horde
# ---------------------------------------------------------------------------
output "horde_url" {
  description = "Horde web UI URL — open in browser to configure projects, streams, and build agents."
  value       = "https://horde.${var.domain_name}"
}

output "horde_alb_dns_name" {
  description = "Application Load Balancer DNS name for Horde and P4 web services."
  value       = module.app_alb.lb_dns_name
}

output "horde_docdb_secret_arn" {
  description = "Secrets Manager ARN containing DocumentDB credentials for Horde's MongoDB connection."
  value       = module.documentdb.credentials_secret_arn
}

output "horde_redis_endpoint" {
  description = "ElastiCache Redis primary endpoint — set as Horde__Redis__ConnectionString in Horde config."
  value       = module.redis.redis_primary_endpoint_address
}

output "horde_agent_asg_name" {
  description = "Auto Scaling Group name for Horde build agents. Use to manually adjust capacity or trigger instance refresh."
  value       = module.horde_agents.asg_name
}

# ---------------------------------------------------------------------------
# ECR Repository URLs
# ---------------------------------------------------------------------------
output "ecr_p4_auth_url" {
  description = "ECR repository URL for the P4 Auth Service container image. Push with: docker push <url>:tag."
  value       = module.ecr.repository_urls["p4-auth"]
}

output "ecr_p4_code_review_url" {
  description = "ECR repository URL for the P4 Code Review container image."
  value       = module.ecr.repository_urls["p4-code-review"]
}

output "ecr_horde_url" {
  description = "ECR repository URL for the Horde Server container image. Build from Epic Games source and push here."
  value       = module.ecr.repository_urls["horde-server"]
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID for the game development pipeline."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (EC2, ECS, DocumentDB, Redis)."
  value       = module.vpc.private_subnet_ids_list
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (NAT Gateways, ALB, NLB)."
  value       = module.vpc.public_subnet_ids_list
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------
output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used for encryption across all services. Null if enable_kms = false."
  value       = local.kms_key_arn
}

# ---------------------------------------------------------------------------
# Convenience: ECR login command
# ---------------------------------------------------------------------------
output "ecr_login_command" {
  description = "Run this command to authenticate Docker with ECR before pushing images."
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# ---------------------------------------------------------------------------
# DocumentDB connection string (non-sensitive — no password)
# ---------------------------------------------------------------------------
output "docdb_connection_string" {
  description = "DocumentDB connection string template. Replace *** with password from credentials_secret_arn."
  value       = module.documentdb.connection_string
}
