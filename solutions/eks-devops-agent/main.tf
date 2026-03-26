# =============================================================================
# EKS AI-Powered Incident Response — main.tf
# Provisions: KMS, S3, VPC, EKS (+ADOT/X-Ray add-ons), AMP, CloudWatch,
#             SNS, IAM, and AWS DevOps Agent via Custom Resource.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# 1. KMS — Customer-managed encryption key
# =============================================================================

module "kms" {
  source = "../../tf-aws-kms"
  count  = var.enable_kms ? 1 : 0

  name_prefix = local.prefix
  tags        = local.tags

  keys = {
    "eks-observability" = {
      description         = "KMS key for EKS, AMP, S3 logs, and CloudWatch — ${local.prefix}"
      enable_key_rotation = true
      service_principals = [
        "logs.amazonaws.com",
        "eks.amazonaws.com",
        "aps.amazonaws.com",
        "s3.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}

# =============================================================================
# 2. S3 — Log storage bucket
# =============================================================================

module "s3_logs" {
  source = "../../tf-aws-s3"

  bucket_name  = "${local.prefix}-logs-${data.aws_caller_identity.current.account_id}"
  environment  = var.environment
  tags         = local.tags
  force_destroy = true

  versioning_enabled = true
  sse_algorithm      = var.enable_kms ? "aws:kms" : "AES256"
  kms_master_key_id  = local.kms_key_arn

  lifecycle_rules = [
    {
      id      = "expire-old-logs"
      enabled = true
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]
}

# =============================================================================
# 3. VPC — Multi-AZ with private/public subnets
# =============================================================================
# Subnet CIDRs are derived from the VPC CIDR using cidrsubnet().
# With a /16 VPC and 3 AZs: public subnets use /24 blocks at .0, .1, .2
# and private subnets use /22 blocks starting at .4 for more node headroom.

locals {
  public_subnet_cidrs = [
    for i, az in var.availability_zones :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]

  private_subnet_cidrs = [
    for i, az in var.availability_zones :
    cidrsubnet(var.vpc_cidr, 4, i + 1)
  ]
}

module "vpc" {
  source = "../../tf-aws-vpc"

  name               = var.name
  environment        = var.environment
  tags               = local.tags
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  enable_nat_gateway  = true
  single_nat_gateway  = var.environment != "prod"
  create_igw          = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS requires these tags on subnets so the load balancer controller
  # can discover which subnets to use for internal/external load balancers.
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.prefix}-eks"   = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.prefix}-eks"   = "owned"
  }

  enable_flow_log              = true
  flow_log_destination_type    = "s3"
  flow_log_destination_arn     = module.s3_logs.bucket_arn
  flow_log_kms_key_id          = local.kms_key_arn

  enable_s3_endpoint = true
}

# =============================================================================
# 4. EKS — Managed Kubernetes cluster + add-ons
# =============================================================================

module "eks" {
  source = "../../tf-aws-eks"

  name        = "${local.prefix}-eks"
  environment = var.environment
  tags        = local.tags

  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids_list

  endpoint_private_access = true
  endpoint_public_access  = false

  secrets_kms_key_arn       = local.kms_key_arn
  cluster_log_kms_key_id    = local.kms_key_arn
  cluster_log_retention_days = var.log_retention_days

  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  enable_irsa = true

  node_groups = {
    primary = {
      instance_types  = var.node_instance_types
      desired_size    = var.node_desired_size
      min_size        = var.node_min_size
      max_size        = var.node_max_size
      ami_type        = "AL2_x86_64"
      capacity_type   = "ON_DEMAND"
      disk_size       = 100
      kms_key_arn     = local.kms_key_arn
      labels = {
        role = "general"
      }
    }
  }

  node_groups_default_subnet_ids = module.vpc.private_subnet_ids_list

  # Core add-ons — ADOT and X-Ray are managed separately below because they
  # require conditional creation based on input variables.
  cluster_addons = {
    coredns            = {}
    kube-proxy         = {}
    vpc-cni            = {}
    aws-ebs-csi-driver = {}
  }
}

# ---------------------------------------------------------------------------
# 4a. ADOT Add-on (AWS Distro for OpenTelemetry)
# ---------------------------------------------------------------------------
resource "aws_eks_addon" "adot" {
  count = var.enable_adot_addon ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "adot"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.tags
}

# ---------------------------------------------------------------------------
# 4b. X-Ray Daemon Add-on
# ---------------------------------------------------------------------------
resource "aws_eks_addon" "xray" {
  count = var.enable_xray_addon ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-guardduty-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.tags
}

# =============================================================================
# 5. AMP — Amazon Managed Prometheus workspace + IRSA + managed scraper
# =============================================================================

module "amp" {
  source = "../../tf-aws-amp"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  kms_key_arn = local.kms_key_arn

  enable_alert_manager = var.enable_alert_manager

  enable_logging     = true
  log_retention_days = var.log_retention_days

  # IRSA — allows in-cluster Prometheus / ADOT to remote_write to AMP
  create_irsa_role               = true
  eks_oidc_provider_arn          = module.eks.oidc_provider_arn
  eks_oidc_issuer_url            = module.eks.oidc_provider_url
  irsa_service_account_namespace = "monitoring"
  irsa_service_account_name      = "amp-iamproxy-ingest-service-account"

  # Managed scraper — pulls metrics directly from EKS without a Prometheus sidecar
  create_managed_scraper     = var.enable_managed_scraper
  scraper_eks_cluster_arn    = module.eks.cluster_arn
  scraper_subnet_ids         = module.vpc.private_subnet_ids_list
  scraper_security_group_ids = [module.eks.cluster_security_group_id]
}

# =============================================================================
# 6. CloudWatch — EKS node and pod metric alarms
# =============================================================================

module "cloudwatch" {
  source = "../../tf-aws-cloudwatch"

  name        = local.prefix
  environment = var.environment
  tags        = local.tags

  # Use the SNS topic from the sns module when email alerting is enabled;
  # otherwise let the cloudwatch module create its own topic (unused).
  create_sns_topic = var.alarm_email == null ? true : false
  sns_topic_arn    = var.alarm_email != null ? module.sns[0].topic_arn : null
  sns_kms_key_id   = local.kms_key_arn

  metric_alarms = {
    eks_node_cpu_high = {
      namespace           = "ContainerInsights"
      metric_name         = "node_cpu_utilization"
      dimensions          = { ClusterName = module.eks.cluster_name }
      threshold           = 80
      comparison_operator = "GreaterThanOrEqualToThreshold"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      treat_missing_data  = "notBreaching"
      alarm_description   = "EKS node CPU utilization >= 80% for 10 minutes — ${local.prefix}"
      severity            = "warning"
    }

    eks_node_memory_high = {
      namespace           = "ContainerInsights"
      metric_name         = "node_memory_utilization"
      dimensions          = { ClusterName = module.eks.cluster_name }
      threshold           = 80
      comparison_operator = "GreaterThanOrEqualToThreshold"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      treat_missing_data  = "notBreaching"
      alarm_description   = "EKS node memory utilization >= 80% for 10 minutes — ${local.prefix}"
      severity            = "warning"
    }

    eks_node_disk_high = {
      namespace           = "ContainerInsights"
      metric_name         = "node_filesystem_utilization"
      dimensions          = { ClusterName = module.eks.cluster_name }
      threshold           = 85
      comparison_operator = "GreaterThanOrEqualToThreshold"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 1
      treat_missing_data  = "notBreaching"
      alarm_description   = "EKS node disk utilization >= 85% — ${local.prefix}"
      severity            = "critical"
    }

    eks_pod_restarts_high = {
      namespace           = "ContainerInsights"
      metric_name         = "pod_number_of_container_restarts"
      dimensions          = { ClusterName = module.eks.cluster_name }
      threshold           = 5
      comparison_operator = "GreaterThanOrEqualToThreshold"
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 1
      treat_missing_data  = "notBreaching"
      alarm_description   = "High pod restart count detected — possible crash loop — ${local.prefix}"
      severity            = "critical"
    }
  }
}

# =============================================================================
# 7. SNS — Alarm notification topic (created only when alarm_email is set)
# =============================================================================

module "sns" {
  source = "../../tf-aws-sns"
  count  = var.alarm_email != null ? 1 : 0

  name        = "${local.prefix}-alerts"
  environment = var.environment
  tags        = local.tags

  kms_master_key_id = local.kms_key_arn

  subscriptions = {
    ops_email = {
      protocol = "email"
      endpoint = var.alarm_email
    }
  }
}

# =============================================================================
# 8. IAM Role — Lambda execution role for DevOps Agent Custom Resource
# =============================================================================

module "devops_agent_cr_role" {
  source = "../../tf-aws-iam-role"

  name        = "${local.prefix}-devops-agent-cr"
  environment = var.environment
  tags        = local.tags

  description = "Lambda execution role for AWS DevOps Agent Space custom resource — ${local.prefix}"

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]

  inline_policies = {
    devops_agent = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DevOpsAgentSpace"
          Effect = "Allow"
          Action = [
            "devops-agent:CreateAgentSpace",
            "devops-agent:DeleteAgentSpace",
            "devops-agent:GetAgentSpace",
            "devops-agent:AssociateDataSource",
            "devops-agent:DisassociateDataSource",
            "devops-agent:ListAgentSpaces",
          ]
          Resource = ["*"]
        },
        {
          Sid    = "AllowKmsForLambda"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey",
          ]
          Resource = local.kms_key_arn != null ? [local.kms_key_arn] : ["*"]
        }
      ]
    })
  }
}

# =============================================================================
# 9. DevOps Agent — Custom Resource via CloudFormation
# =============================================================================

module "devops_agent" {
  source = "../../tf-aws-custom-resource"
  count  = var.enable_devops_agent ? 1 : 0

  name        = "${local.prefix}-devops-agent"
  environment = var.environment
  tags        = local.tags

  # Use the IAM role created above; module will not create its own role
  lambda_role_arn = module.devops_agent_cr_role.role_arn
  create_lambda   = true
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256

  kms_key_arn        = local.kms_key_arn
  log_retention_days = var.log_retention_days

  resource_type = "DevOpsAgentSpace"

  properties = {
    AgentSpaceName = "${local.prefix}-agent-space"
    EksClusterArn  = module.eks.cluster_arn
    PrometheusArn  = module.amp.workspace_arn
    Region         = var.aws_region
  }

  output_attributes = {
    agent_space_id = "AgentSpaceId"
  }

  stack_timeout_minutes = 30
}
