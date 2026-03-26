variable "name" {
  description = "Name for the AMP workspace and related resources."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to all resource names."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
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
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ── Workspace ──────────────────────────────────────────────────────────────────
variable "workspace_alias" {
  description = "Human-readable alias for the AMP workspace. Defaults to name."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting AMP workspace data. Uses AWS-managed key when null."
  type        = string
  default     = null
}

# ── Alert Manager ──────────────────────────────────────────────────────────────
variable "enable_alert_manager" {
  description = "Enable the AMP Alert Manager with the provided definition."
  type        = bool
  default     = false
}

variable "alert_manager_definition" {
  description = <<-EOT
    Alert Manager YAML definition. Only used when enable_alert_manager = true.
    Example:
      alertmanager_config: |
        route:
          receiver: default
        receivers:
          - name: default
  EOT
  type    = string
  default = <<-YAML
alertmanager_config: |
  route:
    receiver: 'default'
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 12h
  receivers:
    - name: 'default'
YAML
}

# ── Rule Groups ────────────────────────────────────────────────────────────────
variable "rule_group_namespaces" {
  description = <<-EOT
    Map of rule group namespace name to YAML Prometheus rules content.
    Example:
      rule_group_namespaces = {
        "eks-rules" = <<-YAML
          groups:
            - name: eks.rules
              rules:
                - alert: HighCPU
                  expr: container_cpu_usage_seconds_total > 0.8
                  for: 5m
        YAML
      }
  EOT
  type    = map(string)
  default = {}
}

# ── IRSA (IAM Roles for Service Accounts) ─────────────────────────────────────
variable "create_irsa_role" {
  description = "Create an IAM role for EKS service accounts (IRSA) so Prometheus can remote-write to AMP."
  type        = bool
  default     = false
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider. Required when create_irsa_role = true."
  type        = string
  default     = null
}

variable "eks_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster (without https://). Required when create_irsa_role = true."
  type        = string
  default     = null
}

variable "irsa_service_account_namespace" {
  description = "Kubernetes namespace of the Prometheus service account."
  type        = string
  default     = "monitoring"
}

variable "irsa_service_account_name" {
  description = "Kubernetes service account name for Prometheus."
  type        = string
  default     = "prometheus"
}

variable "irsa_extra_permissions" {
  description = "Additional IAM actions to grant to the IRSA role (e.g. for AMP query access)."
  type        = list(string)
  default     = []
}

# ── Managed Scraper ────────────────────────────────────────────────────────────
variable "create_managed_scraper" {
  description = "Create an AMP managed scraper that automatically pulls metrics from an EKS cluster."
  type        = bool
  default     = false
}

variable "scraper_eks_cluster_arn" {
  description = "EKS cluster ARN for the managed scraper. Required when create_managed_scraper = true."
  type        = string
  default     = null
}

variable "scraper_subnet_ids" {
  description = "Subnet IDs where the managed scraper runs. Required when create_managed_scraper = true."
  type        = list(string)
  default     = []
}

variable "scraper_security_group_ids" {
  description = "Security group IDs for the managed scraper."
  type        = list(string)
  default     = []
}

variable "scraper_configuration" {
  description = "Prometheus scrape configuration YAML for the managed scraper. Defaults to a standard EKS config."
  type        = string
  default     = null
}

# ── Logging ────────────────────────────────────────────────────────────────────
variable "enable_logging" {
  description = "Enable CloudWatch logging for AMP alert manager and rule evaluations."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}
