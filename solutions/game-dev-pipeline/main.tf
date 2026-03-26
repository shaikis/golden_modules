# =============================================================================
# Game Development Pipeline — main.tf
# Perforce P4 Version Control + Unreal Engine Horde CI/CD on AWS
#
# Reference:
#   https://aws.amazon.com/blogs/gametech/game-development-infrastructure-simplified-with-aws-game-dev-toolkit/
# =============================================================================

# ---------------------------------------------------------------------------
# Section 19: Data Sources
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Section 1: KMS — Customer-Managed Encryption Key
# Encrypts EBS volumes, S3 buckets, DocumentDB storage, and Secrets Manager
# ---------------------------------------------------------------------------
module "kms" {
  count  = var.enable_kms ? 1 : 0
  source = "../../tf-aws-kms"

  name_prefix = local.prefix
  tags        = local.tags

  keys = {
    "gamedev" = {
      description         = "KMS key for ${local.prefix} game dev pipeline encryption"
      enable_key_rotation = true
      service_principals = [
        "s3.amazonaws.com",
        "secretsmanager.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "docdb.amazonaws.com",
        "logs.${var.aws_region}.amazonaws.com",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Section 2: VPC — Multi-AZ Network Foundation
# Public subnets host NAT Gateways and load balancers.
# Private subnets host EC2 instances, ECS tasks, DocumentDB, and Redis.
# NAT Gateway per AZ for high availability.
# ---------------------------------------------------------------------------
module "vpc" {
  source = "../../tf-aws-vpc"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  # NAT Gateway per AZ — ensures private subnet egress survives an AZ failure
  enable_nat_gateway = true
  single_nat_gateway = false

  create_igw = true

  # VPC Flow Logs for security auditing and troubleshooting
  enable_flow_log            = true
  flow_log_destination_type  = "cloud-watch-logs"
  flow_log_traffic_type      = "ALL"
  flow_log_retention_days    = 90
  flow_log_kms_key_id        = local.kms_key_arn

  # S3 VPC endpoint — build agents pull artifacts without traversing NAT Gateway
  enable_s3_endpoint = true

  # Tag public subnets for game-dev load balancer placement
  public_subnet_tags = {
    "game-dev/subnet-type" = "public"
    "game-dev/elb"         = "1"
  }

  # Tag private subnets for internal workload placement
  private_subnet_tags = {
    "game-dev/subnet-type"    = "private"
    "game-dev/internal-elb"   = "1"
  }
}

# ---------------------------------------------------------------------------
# Section 3: ACM Certificate — Wildcard TLS for all services
# *.games.example.com covers horde.games.example.com, p4.games.example.com
# ---------------------------------------------------------------------------
module "acm" {
  source = "../../tf-aws-acm"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"
  route53_zone_id           = var.route53_zone_id
  wait_for_validation       = true
}

# ---------------------------------------------------------------------------
# Section 4: S3 Buckets
# build-artifacts: stores compiled Unreal Engine builds, packaged games
# p4-backups:      stores Perforce depot backups (checkpoint + journal files)
# ---------------------------------------------------------------------------
module "s3_build_artifacts" {
  source = "../../tf-aws-s3"

  bucket_name       = "${local.prefix}-build-artifacts"
  environment       = var.environment
  tags              = local.tags
  versioning_enabled = true
  sse_algorithm     = var.enable_kms ? "aws:kms" : "AES256"
  kms_master_key_id = local.kms_key_arn

  # Build artifacts older than 90 days transition to cheaper storage
  lifecycle_rules = [
    {
      id      = "transition-old-builds"
      enabled = true
      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]
}

module "s3_p4_backups" {
  source = "../../tf-aws-s3"

  bucket_name       = "${local.prefix}-p4-backups"
  environment       = var.environment
  tags              = local.tags
  versioning_enabled = true
  sse_algorithm     = var.enable_kms ? "aws:kms" : "AES256"
  kms_master_key_id = local.kms_key_arn

  # Keep P4 backups for 1 year; transition to Glacier after 30 days
  lifecycle_rules = [
    {
      id      = "archive-p4-backups"
      enabled = true
      transition = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 365
      }
    }
  ]
}

# ---------------------------------------------------------------------------
# Section 5: ECR Repositories
# Container images for Perforce services and Horde Controller
# ---------------------------------------------------------------------------
module "ecr" {
  source = "../../tf-aws-ecr"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  kms_key_arn = local.kms_key_arn

  repositories = {
    "p4-auth" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = var.enable_kms ? "KMS" : "AES256"
    }
    "p4-code-review" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = var.enable_kms ? "KMS" : "AES256"
    }
    "horde-server" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = var.enable_kms ? "KMS" : "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# Section 6: Secrets Manager
# ---------------------------------------------------------------------------
module "secret_p4_admin" {
  source = "../../tf-aws-secretsmanager"

  name        = "${local.prefix}-p4-admin"
  environment = var.environment
  tags        = local.tags

  description          = "Perforce P4D admin credentials for ${local.prefix}. Change password on first login."
  kms_key_id           = local.kms_key_arn
  recovery_window_days = 30

  secret_string = jsonencode({
    username = "admin"
    password = "CHANGE_ME_ON_FIRST_LOGIN"
    email    = var.p4_admin_email
  })
}

module "secret_horde" {
  source = "../../tf-aws-secretsmanager"

  name        = "${local.prefix}-horde-credentials"
  environment = var.environment
  tags        = local.tags

  description          = "Horde Controller credentials and integration secrets for ${local.prefix}."
  kms_key_id           = local.kms_key_arn
  recovery_window_days = 30

  secret_string = jsonencode({
    horde_db_secret_arn = "TBD"
    slack_webhook       = ""
  })
}

# ---------------------------------------------------------------------------
# Section 7: Security Groups
# ---------------------------------------------------------------------------

# ALB security group — internet-facing, accepts HTTPS and HTTP
resource "aws_security_group" "alb" {
  name        = "${local.prefix}-alb"
  description = "ALB security group for Horde web UI and Perforce web services"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress {
    description = "HTTPS from studio and authorized IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.horde_allowed_cidrs
  }

  ingress {
    description = "HTTP — redirected to HTTPS by ALB listener"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.horde_allowed_cidrs
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS services security group — accepts traffic from ALB only
resource "aws_security_group" "ecs_services" {
  name        = "${local.prefix}-ecs-services"
  description = "ECS services security group for P4 Auth, P4 Code Review, and Horde Controller"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "P4 Auth service HTTP port"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "P4 Code Review / Horde web UI port"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Horde agent communication port"
    from_port       = 5004
    to_port         = 5004
    protocol        = "tcp"
    security_groups = [aws_security_group.horde_agents.id]
  }

  egress {
    description = "All outbound (DocumentDB, Redis, P4, ECR, Secrets Manager)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Perforce P4 commit server security group — TCP 1666 for P4V clients
resource "aws_security_group" "p4_server" {
  name        = "${local.prefix}-p4-server"
  description = "Perforce P4D Commit Server — allows P4V connections on TCP/1666"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress {
    description = "Perforce protocol (P4V, P4 CLI, build agents)"
    from_port   = 1666
    to_port     = 1666
    protocol    = "tcp"
    cidr_blocks = var.p4_allowed_cidrs
  }

  ingress {
    description = "SSH for admin access via bastion or SSM session"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.p4_allowed_cidrs
  }

  egress {
    description = "All outbound (AWS APIs, package repos, S3 backup)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Horde build agents security group — outbound to P4 server and Horde controller
resource "aws_security_group" "horde_agents" {
  name        = "${local.prefix}-horde-agents"
  description = "Horde build agent EC2 instances — auto-scaled Windows Spot fleet"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress {
    description     = "Horde agent RPC port — Horde Controller connects back to agents"
    from_port       = 7010
    to_port         = 7010
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_services.id]
  }

  egress {
    description = "All outbound (P4 depot, S3 artifacts, Horde controller, ECR)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# Section 8: IAM Roles
# ---------------------------------------------------------------------------

# P4 Commit Server EC2 instance role — SSM, CloudWatch, S3 backup
module "iam_p4_server" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-p4-server"
  environment = var.environment
  tags        = local.tags

  description              = "P4 Commit Server EC2 instance role — SSM session manager, CloudWatch metrics, S3 backup writes"
  trusted_role_services    = ["ec2.amazonaws.com"]
  create_instance_profile  = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]

  inline_policies = {
    p4-s3-backup = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "P4BackupBucketAccess"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
          ]
          Resource = [
            module.s3_p4_backups.bucket_arn,
            "${module.s3_p4_backups.bucket_arn}/*",
          ]
        },
        {
          Sid    = "P4SecretsAccess"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
          ]
          Resource = [module.secret_p4_admin.secret_arn]
        },
      ]
    })
  }
}

# ECS Task Execution Role — pulled images from ECR, writes logs to CloudWatch
module "iam_ecs_execution" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-ecs-execution"
  environment = var.environment
  tags        = local.tags

  description           = "ECS task execution role — ECR image pull, CloudWatch Logs, Secrets Manager reads"
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]

  inline_policies = {
    ecs-secrets-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "SecretsManagerRead"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
          ]
          Resource = [
            module.secret_p4_admin.secret_arn,
            module.secret_horde.secret_arn,
          ]
        },
        {
          Sid    = "KMSDecrypt"
          Effect = "Allow"
          Action = ["kms:Decrypt", "kms:GenerateDataKey"]
          Resource = local.kms_key_arn != null ? [local.kms_key_arn] : ["*"]
        },
      ]
    })
  }
}

# ECS Task Role — runtime permissions for P4 Auth, P4 Code Review, Horde services
module "iam_ecs_task" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-ecs-task"
  environment = var.environment
  tags        = local.tags

  description           = "ECS task runtime role — S3 artifacts, Secrets Manager, CloudWatch"
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  inline_policies = {
    ecs-task-permissions = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "S3ArtifactsAccess"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
          ]
          Resource = [
            module.s3_build_artifacts.bucket_arn,
            "${module.s3_build_artifacts.bucket_arn}/*",
          ]
        },
        {
          Sid    = "SecretsAccess"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
          ]
          Resource = [
            module.secret_p4_admin.secret_arn,
            module.secret_horde.secret_arn,
            module.documentdb.credentials_secret_arn,
          ]
        },
        {
          Sid    = "CloudWatchMetrics"
          Effect = "Allow"
          Action = ["cloudwatch:PutMetricData"]
          Resource = ["*"]
        },
      ]
    })
  }
}

# Horde Build Agent role — SSM, ECR pull, S3 artifacts
module "iam_horde_agent" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-horde-agent"
  environment = var.environment
  tags        = local.tags

  description              = "Horde build agent EC2 role — SSM, ECR image pull, S3 artifact push"
  trusted_role_services    = ["ec2.amazonaws.com"]
  create_instance_profile  = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]

  inline_policies = {
    horde-agent-permissions = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "S3ArtifactsReadWrite"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
          ]
          Resource = [
            module.s3_build_artifacts.bucket_arn,
            "${module.s3_build_artifacts.bucket_arn}/*",
          ]
        },
        {
          Sid    = "ECRAuth"
          Effect = "Allow"
          Action = ["ecr:GetAuthorizationToken"]
          Resource = ["*"]
        },
        {
          Sid    = "SecretsRead"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
          ]
          Resource = [module.secret_horde.secret_arn]
        },
      ]
    })
  }
}

# ---------------------------------------------------------------------------
# Section 9: P4 Commit Server (EC2)
# Amazon Linux 2023 — optimal for P4D Linux binary
# Placed in private subnet; exposed externally via NLB on TCP/1666
# ---------------------------------------------------------------------------
module "p4_server" {
  source = "../../tf-aws-ec2"

  name        = "${local.prefix}-p4-server"
  environment = var.environment
  tags        = local.tags

  # Amazon Linux 2023 — leave empty for auto-latest AMI selection by the module
  ami_id        = ""
  instance_type = var.p4_instance_type

  # Private subnet in first AZ — collocates with the EBS data volume
  subnet_id              = module.vpc.private_subnet_ids_list[0]
  vpc_security_group_ids = [aws_security_group.p4_server.id]

  iam_instance_profile = module.iam_p4_server.instance_profile_name

  # IMDSv2 required, disable API termination to protect depot data
  disable_api_termination = true
  monitoring              = true

  # Root volume — OS only; P4 depot data lives on the separate EBS volume
  root_volume_type      = "gp3"
  root_volume_size      = 50
  root_volume_encrypted = true
  root_volume_kms_key_id = local.kms_key_arn

  user_data = base64encode(file("${path.module}/userdata/p4_server_linux.sh"))

  user_data_replace_on_change = false
}

# ---------------------------------------------------------------------------
# Section 10: EBS Volume for P4 Depot Data
# Separate from root — survives instance replacement, can be snapshotted
# ---------------------------------------------------------------------------
module "p4_data_volume" {
  source = "../../tf-aws-ebs"

  name        = "${local.prefix}-p4-data"
  environment = var.environment
  tags        = local.tags

  kms_key_arn = local.kms_key_arn

  volumes = {
    "p4-depot" = {
      availability_zone = var.availability_zones[0]
      size              = var.p4_data_volume_size_gb
      type              = var.p4_data_volume_type
      iops              = var.p4_data_volume_iops
      throughput        = 250  # MB/s — gp3 default; increase for large repos
      final_snapshot    = true # Create a snapshot before Terraform destroys the volume
      additional_tags = {
        "game-dev/purpose" = "p4-depot-data"
      }
    }
  }

  # Attach the volume to the P4 server as /dev/xvdf
  volume_attachments = {
    "p4-depot-attach" = {
      volume_key  = "p4-depot"
      instance_id = module.p4_server.instance_id
      device_name = "/dev/xvdf"
    }
  }

  # Automated daily snapshots via DLM — 7-day retention
  enable_dlm = true
  dlm_target_tags = {
    "game-dev/purpose" = "p4-depot-data"
  }
}

# ---------------------------------------------------------------------------
# Section 11: Network Load Balancer for Perforce TCP/1666
# NLB preserves client IPs and handles raw TCP — required for P4 protocol
# ---------------------------------------------------------------------------
module "p4_nlb" {
  source = "../../tf-aws-alb"

  name        = "${local.prefix}-p4-nlb"
  environment = var.environment
  tags        = local.tags

  load_balancer_type        = "network"
  internal                  = false
  subnets                   = module.vpc.public_subnet_ids_list
  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true

  target_groups = {
    "p4-tcp-1666" = {
      port        = 1666
      protocol    = "TCP"
      target_type = "instance"
      vpc_id      = module.vpc.vpc_id
      health_check = {
        enabled             = true
        protocol            = "TCP"
        port                = "traffic-port"
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }

  listeners = {
    "p4-tcp" = {
      port     = 1666
      protocol = "TCP"
      default_action = {
        type             = "forward"
        target_group_key = "p4-tcp-1666"
      }
    }
  }
}

# Register P4 server instance with NLB target group
resource "aws_lb_target_group_attachment" "p4_server" {
  target_group_arn = module.p4_nlb.target_group_arns["p4-tcp-1666"]
  target_id        = module.p4_server.instance_id
  port             = 1666
}

# ---------------------------------------------------------------------------
# Section 12: Application Load Balancer for Web Services
# Handles HTTPS for P4 Auth, P4 Code Review, and Horde web UI
# HTTP listener redirects to HTTPS (TLS termination at ALB)
# ---------------------------------------------------------------------------
module "app_alb" {
  source = "../../tf-aws-alb"

  name        = "${local.prefix}-app-alb"
  environment = var.environment
  tags        = local.tags

  load_balancer_type         = "application"
  internal                   = false
  subnets                    = module.vpc.public_subnet_ids_list
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = true
  enable_http2               = true
  drop_invalid_header_fields = true

  target_groups = {
    "p4-auth" = {
      port             = 3000
      protocol         = "HTTP"
      protocol_version = "HTTP1"
      target_type      = "ip"
      vpc_id           = module.vpc.vpc_id
      health_check = {
        enabled             = true
        path                = "/healthcheck"
        port                = "traffic-port"
        protocol            = "HTTP"
        matcher             = "200-299"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
    "p4-code-review" = {
      port             = 8080
      protocol         = "HTTP"
      protocol_version = "HTTP1"
      target_type      = "ip"
      vpc_id           = module.vpc.vpc_id
      health_check = {
        enabled             = true
        path                = "/healthcheck"
        port                = "traffic-port"
        protocol            = "HTTP"
        matcher             = "200-299"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
    "horde" = {
      port             = 8080
      protocol         = "HTTP"
      protocol_version = "HTTP1"
      target_type      = "ip"
      vpc_id           = module.vpc.vpc_id
      health_check = {
        enabled             = true
        path                = "/healthz"
        port                = "traffic-port"
        protocol            = "HTTP"
        matcher             = "200-299"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
      stickiness = {
        enabled         = true
        type            = "lb_cookie"
        cookie_duration = 86400
      }
    }
  }

  listeners = {
    "https" = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = module.acm.certificate_arn
      default_action = {
        type             = "forward"
        target_group_key = "horde"
      }
    }
    "http-redirect" = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Section 13: ECS Cluster
# Shared Fargate cluster for P4 Auth, P4 Code Review, and Horde Controller
# ---------------------------------------------------------------------------
module "ecs_cluster" {
  source = "../../tf-aws-ecs"

  name        = "${local.prefix}-gamedev"
  environment = var.environment
  tags        = local.tags

  container_insights = true
  kms_key_arn        = local.kms_key_arn
  use_fargate        = true
  use_fargate_spot   = false

  # ---------------------------------------------------------------------------
  # Section 14: ECS Task Definitions and Services
  # ---------------------------------------------------------------------------

  task_definitions = {
    "p4-auth" = {
      cpu    = 512
      memory = 1024
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      execution_role_arn       = module.iam_ecs_execution.role_arn
      task_role_arn            = module.iam_ecs_task.role_arn

      container_definitions = jsonencode([
        {
          name      = "p4-auth"
          image     = "${module.ecr.repository_urls["p4-auth"]}:latest"
          essential = true
          portMappings = [
            { containerPort = 3000, protocol = "tcp" }
          ]
          environment = [
            { name = "P4PORT", value = "ssl:${module.p4_nlb.lb_dns_name}:1666" },
            { name = "SVC_BASE_URL", value = "https://p4auth.${var.domain_name}" },
          ]
          secrets = [
            {
              name      = "P4_ADMIN_PASSWORD"
              valueFrom = "${module.secret_p4_admin.secret_arn}:password::"
            }
          ]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/${local.prefix}/p4-auth"
              "awslogs-region"        = var.aws_region
              "awslogs-stream-prefix" = "p4-auth"
              "awslogs-create-group"  = "true"
            }
          }
          healthCheck = {
            command     = ["CMD-SHELL", "curl -f http://localhost:3000/healthcheck || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 60
          }
        }
      ])
    }

    "p4-code-review" = {
      cpu    = 1024
      memory = 2048
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      execution_role_arn       = module.iam_ecs_execution.role_arn
      task_role_arn            = module.iam_ecs_task.role_arn

      container_definitions = jsonencode([
        {
          name      = "p4-code-review"
          image     = "${module.ecr.repository_urls["p4-code-review"]}:latest"
          essential = true
          portMappings = [
            { containerPort = 8080, protocol = "tcp" }
          ]
          environment = [
            { name = "P4PORT", value = "ssl:${module.p4_nlb.lb_dns_name}:1666" },
            { name = "SVC_BASE_URL", value = "https://review.${var.domain_name}" },
          ]
          secrets = [
            {
              name      = "P4_ADMIN_PASSWORD"
              valueFrom = "${module.secret_p4_admin.secret_arn}:password::"
            }
          ]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/${local.prefix}/p4-code-review"
              "awslogs-region"        = var.aws_region
              "awslogs-stream-prefix" = "p4-code-review"
              "awslogs-create-group"  = "true"
            }
          }
        }
      ])
    }

    "horde" = {
      cpu    = 2048
      memory = 4096
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      execution_role_arn       = module.iam_ecs_execution.role_arn
      task_role_arn            = module.iam_ecs_task.role_arn

      container_definitions = jsonencode([
        {
          name      = "horde-server"
          image     = "${module.ecr.repository_urls["horde-server"]}:latest"
          essential = true
          portMappings = [
            { containerPort = 8080, protocol = "tcp", name = "web-ui" },
            { containerPort = 5004, protocol = "tcp", name = "agent-rpc" },
          ]
          environment = [
            { name = "Horde__Mongo__ConnectionString", value = "mongodb://${module.documentdb.cluster_endpoint}:${module.documentdb.port}/?tls=true&tlsCAFile=/etc/ssl/certs/rds-combined-ca-bundle.pem&replicaSet=rs0" },
            { name = "Horde__Redis__ConnectionString", value = "${module.redis.redis_primary_endpoint_address}:6379" },
            { name = "Horde__ServerUrl", value = "https://horde.${var.domain_name}" },
            { name = "Horde__P4__ServerAndPort", value = "ssl:${module.p4_nlb.lb_dns_name}:1666" },
          ]
          secrets = [
            {
              name      = "Horde__Mongo__Credentials"
              valueFrom = module.documentdb.credentials_secret_arn
            },
            {
              name      = "Horde__Credentials"
              valueFrom = module.secret_horde.secret_arn
            }
          ]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/${local.prefix}/horde"
              "awslogs-region"        = var.aws_region
              "awslogs-stream-prefix" = "horde"
              "awslogs-create-group"  = "true"
            }
          }
          healthCheck = {
            command     = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
            interval    = 30
            timeout     = 10
            retries     = 3
            startPeriod = 120
          }
        }
      ])
    }
  }

  services = {
    "p4-auth-service" = {
      task_definition_key    = "p4-auth"
      desired_count          = 1
      launch_type            = "FARGATE"
      enable_execute_command = true

      network_configuration = {
        subnets          = module.vpc.private_subnet_ids_list
        security_groups  = [aws_security_group.ecs_services.id]
        assign_public_ip = false
      }

      load_balancers = [
        {
          target_group_arn = module.app_alb.target_group_arns["p4-auth"]
          container_name   = "p4-auth"
          container_port   = 3000
        }
      ]

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }
    }

    "p4-code-review-service" = {
      task_definition_key    = "p4-code-review"
      desired_count          = 1
      launch_type            = "FARGATE"
      enable_execute_command = true

      network_configuration = {
        subnets          = module.vpc.private_subnet_ids_list
        security_groups  = [aws_security_group.ecs_services.id]
        assign_public_ip = false
      }

      load_balancers = [
        {
          target_group_arn = module.app_alb.target_group_arns["p4-code-review"]
          container_name   = "p4-code-review"
          container_port   = 8080
        }
      ]

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }
    }

    "horde-service" = {
      task_definition_key    = "horde"
      desired_count          = 1
      launch_type            = "FARGATE"
      enable_execute_command = true

      network_configuration = {
        subnets          = module.vpc.private_subnet_ids_list
        security_groups  = [aws_security_group.ecs_services.id]
        assign_public_ip = false
      }

      load_balancers = [
        {
          target_group_arn = module.app_alb.target_group_arns["horde"]
          container_name   = "horde-server"
          container_port   = 8080
        }
      ]

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Section 15: DocumentDB — MongoDB-Compatible Database for Horde
# Horde stores build jobs, agent registrations, test results, and telemetry
# ---------------------------------------------------------------------------
module "documentdb" {
  source = "../../tf-aws-documentdb"

  name        = "${local.prefix}-horde"
  environment = var.environment
  tags        = local.tags

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids_list

  cluster_size   = var.docdb_cluster_size
  instance_class = var.docdb_instance_class

  # Allow Horde ECS tasks to connect
  allowed_security_group_ids = [aws_security_group.ecs_services.id]

  # Encryption
  storage_encrypted = true
  kms_key_id        = local.kms_key_arn
  tls_enabled       = true

  # Backup — 7-day automated backups
  backup_retention_days        = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  # Protect production cluster from accidental deletion
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${local.prefix}-horde-final-snapshot"

  enabled_cloudwatch_logs = ["audit", "profiler"]
  log_retention_days      = 14
}

# ---------------------------------------------------------------------------
# Section 16: ElastiCache Redis — Horde Session Cache and Job Queue
# ---------------------------------------------------------------------------

# Security group for Redis — only ECS services can connect
resource "aws_security_group" "redis" {
  name        = "${local.prefix}-redis"
  description = "ElastiCache Redis security group — Horde Controller access only"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress {
    description     = "Redis from Horde ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_services.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "redis" {
  source = "../../tf-aws-elasticache"

  name        = "${local.prefix}-horde-cache"
  environment = var.environment
  tags        = local.tags

  engine       = "redis"
  engine_version = "7.0"
  node_type    = var.redis_node_type
  port         = 6379

  # Replication group — 1 primary + 1 replica for Multi-AZ failover
  num_cache_clusters      = var.redis_num_cache_nodes
  automatic_failover_enabled = true
  multi_az_enabled        = true

  subnet_ids         = module.vpc.private_subnet_ids_list
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  kms_key_id                  = local.kms_key_arn

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "sun:05:00-sun:06:00"

  parameter_group_family = "redis7"
}

# ---------------------------------------------------------------------------
# Section 17: Auto Scaling Group — Horde Build Agents
# Windows Server 2022 with Unreal Engine build dependencies
# Mixed Instances Policy with Spot for cost optimization
# ---------------------------------------------------------------------------
module "horde_agents" {
  source = "../../tf-aws-asg"

  name        = "${local.prefix}-horde-agents"
  environment = var.environment
  tags        = local.tags

  os_type                   = "windows"
  instance_type             = var.horde_agent_instance_type
  iam_instance_profile_name = module.iam_horde_agent.instance_profile_name
  security_group_ids        = [aws_security_group.horde_agents.id]

  vpc_zone_identifier = module.vpc.private_subnet_ids_list
  min_size            = var.horde_agent_min_size
  max_size            = var.horde_agent_max_size
  desired_capacity    = var.horde_agent_desired

  # Large root volume — Unreal Engine requires 100+ GB for engine and cache
  root_volume_size = 200
  root_volume_type = "gp3"
  kms_key_arn      = local.kms_key_arn

  # Spot mixed instances policy when horde_use_spot = true
  use_mixed_instances_policy       = var.horde_use_spot
  on_demand_base_capacity          = var.horde_use_spot ? 0 : var.horde_agent_min_size
  on_demand_percentage_above_base  = var.horde_use_spot ? 0 : 100
  spot_allocation_strategy         = "price-capacity-optimized"

  # Additional instance types for Spot diversification
  override_instance_types = [
    var.horde_agent_instance_type,
    "c5.4xlarge",
    "c5a.4xlarge",
    "c5n.4xlarge",
    "m5.4xlarge",
    "m5a.4xlarge",
  ]

  # CPU-based auto-scaling — scale out at 70% CPU to start new build VMs before saturation
  enable_cpu_scaling = true
  cpu_target_value   = 70

  health_check_type         = "EC2"
  health_check_grace_period = 600  # Windows takes longer to boot and register

  # Capacity Rebalance — proactively replace Spot instances before interruption
  capacity_rebalance = var.horde_use_spot

  # IMDSv2 hop limit = 2 for container workloads on Horde agents
  metadata_http_put_response_hop_limit = 2

  user_data = base64encode(templatefile("${path.module}/userdata/horde_agent_windows.ps1", {
    horde_server_url = "https://horde.${var.domain_name}"
    ecr_registry     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  }))
}

# ---------------------------------------------------------------------------
# Section 18: Route 53 DNS Records
# horde.${var.domain_name}  → App ALB (Horde web UI)
# p4.${var.domain_name}     → P4 NLB (Perforce TCP/1666)
# ---------------------------------------------------------------------------
module "dns" {
  source = "../../tf-aws-route53"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  records = {
    "horde" = {
      zone_id = var.route53_zone_id
      name    = "horde.${var.domain_name}"
      type    = "A"
      alias_target = {
        name                   = module.app_alb.lb_dns_name
        zone_id                = module.app_alb.lb_zone_id
        evaluate_target_health = true
      }
    }
    "p4" = {
      zone_id = var.route53_zone_id
      name    = "p4.${var.domain_name}"
      type    = "A"
      alias_target = {
        name                   = module.p4_nlb.lb_dns_name
        zone_id                = module.p4_nlb.lb_zone_id
        evaluate_target_health = true
      }
    }
    "p4auth" = {
      zone_id = var.route53_zone_id
      name    = "p4auth.${var.domain_name}"
      type    = "A"
      alias_target = {
        name                   = module.app_alb.lb_dns_name
        zone_id                = module.app_alb.lb_zone_id
        evaluate_target_health = true
      }
    }
    "review" = {
      zone_id = var.route53_zone_id
      name    = "review.${var.domain_name}"
      type    = "A"
      alias_target = {
        name                   = module.app_alb.lb_dns_name
        zone_id                = module.app_alb.lb_zone_id
        evaluate_target_health = true
      }
    }
  }
}
