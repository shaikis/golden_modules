# =============================================================================
# Example: Session Manager — No Bastion Host Required
# =============================================================================
# Replace EC2 bastion host with AWS Systems Manager Session Manager.
# Benefits:
#   - No port 22 inbound rules needed
#   - No SSH key management
#   - All sessions audited in CloudWatch Logs + S3
#   - IAM-controlled access (MFA, SCPs, conditions)
#   - Port forwarding to RDS, Redis, private services
#   - Works from AWS Console, AWS CLI, and VS Code Remote
#
# Reference: Generali Malaysia EKS security pattern
# https://aws.amazon.com/blogs/architecture/how-generali-malaysia-optimizes-operations-with-amazon-eks/
# =============================================================================

module "ssm_session_manager" {
  source      = "../../"
  name        = "mycompany"
  environment = "prod"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  # ---------------------------------------------------------------------------
  # SESSION MANAGER CONFIGURATION
  # ---------------------------------------------------------------------------
  enable_session_manager = true

  # S3 bucket for session recordings (audit trail)
  session_manager_s3_bucket = "mycompany-prod-ssm-session-logs"
  session_manager_s3_prefix = "prod/session-logs/"

  # CloudWatch Logs for real-time session streaming
  session_manager_cloudwatch_log_group = "/aws/ssm/session-manager/mycompany-prod"
  session_manager_log_retention_days   = 90 # 90 days for compliance

  tags = {
    CostCenter = "platform"
    Compliance = "SOC2-CC6.1"
  }
}

# ---------------------------------------------------------------------------
# Attach Session Manager policy to EC2 instance roles
# ---------------------------------------------------------------------------
# For each EC2 instance role, attach the policy output from the module:
#
# resource "aws_iam_role_policy_attachment" "ssm_on_ec2" {
#   role       = aws_iam_role.ec2_instance_role.name
#   policy_arn = module.ssm_session_manager.session_manager_policy_arn
# }
#
# OR use the AWS managed policy (broader permissions):
# resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
#   role       = aws_iam_role.ec2_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# ---------------------------------------------------------------------------
# IAM policy for ENGINEERS to start sessions (least-privilege)
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "engineer_session_manager" {
  name        = "EngineerSessionManagerAccess"
  description = "Allows engineers to start SSM sessions on tagged production instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StartSessionOnTaggedInstances"
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = [
          "arn:aws:ec2:*:*:instance/*"
        ]
        Condition = {
          StringEquals = {
            "ssm:resourceTag/Environment"          = ["prod"]
            "ssm:resourceTag/SessionManagerAccess" = ["true"]
          }
        }
      },
      {
        Sid    = "StartPortForwardingSession"
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = ["arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"]
      },
      {
        Sid    = "StartPortForwardingToRemoteHostSession"
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = ["arn:aws:ssm:*:*:document/AWS-StartPortForwardingSessionToRemoteHost"]
      },
      {
        Sid    = "SessionLifecycle"
        Effect = "Allow"
        Action = [
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceProperties",
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerminateOwnSessions"
        Effect = "Allow"
        Action = ["ssm:TerminateSession", "ssm:ResumeSession"]
        # Engineers can only terminate their own sessions ($${aws:username} resolves at policy eval time)
        Resource = ["arn:aws:ssm:*:*:session/$${aws:username}-*"]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# VPC Endpoints — required for private subnets WITHOUT NAT Gateway
# Optional but strongly recommended: keeps SSM traffic off the public internet
# ---------------------------------------------------------------------------
# Uncomment and fill in vpc_id, private_subnet_ids, and security_group_ids:
#
# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = var.vpc_id
#   service_name        = "com.amazonaws.us-east-1.ssm"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = var.private_subnet_ids
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = { Name = "ssm-endpoint" }
# }
#
# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id              = var.vpc_id
#   service_name        = "com.amazonaws.us-east-1.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = var.private_subnet_ids
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = { Name = "ssmmessages-endpoint" }
# }
#
# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id              = var.vpc_id
#   service_name        = "com.amazonaws.us-east-1.ec2messages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = var.private_subnet_ids
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = { Name = "ec2messages-endpoint" }
# }
#
# resource "aws_vpc_endpoint" "s3" {
#   # S3 Gateway endpoint — free, no security group required
#   vpc_id            = var.vpc_id
#   service_name      = "com.amazonaws.us-east-1.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = var.private_route_table_ids
#
#   tags = { Name = "s3-gateway-endpoint" }
# }
#
# resource "aws_security_group" "vpc_endpoints" {
#   name        = "vpc-endpoints-sg"
#   description = "Allow HTTPS from VPC CIDR to interface VPC endpoints"
#   vpc_id      = var.vpc_id
#
#   ingress {
#     description = "HTTPS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [data.aws_vpc.main.cidr_block]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

output "session_manager_policy_arn" {
  description = "Attach this policy ARN to EC2 instance IAM roles to enable Session Manager"
  value       = module.ssm_session_manager.session_manager_policy_arn
}

output "session_log_group" {
  description = "CloudWatch Log Group streaming all session activity"
  value       = module.ssm_session_manager.session_manager_log_group_name
}

output "engineer_policy_arn" {
  description = "Attach to engineer IAM users/roles to grant Session Manager console + CLI access"
  value       = aws_iam_policy.engineer_session_manager.arn
}
