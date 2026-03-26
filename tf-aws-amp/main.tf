locals {
  name_prefix     = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  workspace_alias = var.workspace_alias != null ? var.workspace_alias : local.name_prefix

  # Strip https:// from OIDC issuer URL for IAM condition
  oidc_issuer = var.eks_oidc_issuer_url != null ? trimprefix(var.eks_oidc_issuer_url, "https://") : ""

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  default_scraper_config = <<-YAML
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: true
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: true
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)

  - job_name: 'kubernetes-service-endpoints'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
YAML
}

# ── AMP Workspace ───────────────────────────────────────────────────────────────
resource "aws_prometheus_workspace" "this" {
  alias       = local.workspace_alias
  kms_key_arn = var.kms_key_arn
  tags        = local.common_tags

  dynamic "logging_configuration" {
    for_each = var.enable_logging ? [1] : []
    content {
      log_group_arn = "${aws_cloudwatch_log_group.amp[0].arn}:*"
    }
  }
}

# ── CloudWatch Log Group ────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "amp" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/prometheus/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

# ── Alert Manager Definition ────────────────────────────────────────────────────
resource "aws_prometheus_alert_manager_definition" "this" {
  count = var.enable_alert_manager ? 1 : 0

  workspace_id = aws_prometheus_workspace.this.id
  definition   = var.alert_manager_definition
}

# ── Rule Group Namespaces ───────────────────────────────────────────────────────
resource "aws_prometheus_rule_group_namespace" "this" {
  for_each = var.rule_group_namespaces

  workspace_id = aws_prometheus_workspace.this.id
  name         = each.key
  data         = each.value
}

# ── IRSA Role — allows EKS Prometheus service account to remote-write to AMP ───
resource "aws_iam_role" "irsa" {
  count = var.create_irsa_role ? 1 : 0

  name = "${local.name_prefix}-amp-irsa"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.eks_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:${var.irsa_service_account_namespace}:${var.irsa_service_account_name}"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "irsa" {
  count = var.create_irsa_role ? 1 : 0

  name = "${local.name_prefix}-amp-irsa-policy"
  role = aws_iam_role.irsa[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "AMPRemoteWrite"
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.this.arn
      }
    ],
    length(var.irsa_extra_permissions) > 0 ? [{
      Sid      = "ExtraPermissions"
      Effect   = "Allow"
      Action   = var.irsa_extra_permissions
      Resource = "*"
    }] : [])
  })
}

# ── Managed Scraper ─────────────────────────────────────────────────────────────
resource "aws_prometheus_scraper" "this" {
  count = var.create_managed_scraper ? 1 : 0

  scrape_configuration = var.scraper_configuration != null ? var.scraper_configuration : local.default_scraper_config

  source {
    eks {
      cluster_arn        = var.scraper_eks_cluster_arn
      subnet_ids         = var.scraper_subnet_ids
      security_group_ids = var.scraper_security_group_ids
    }
  }

  destination {
    amp {
      workspace_arn = aws_prometheus_workspace.this.arn
    }
  }

  tags = local.common_tags
}
