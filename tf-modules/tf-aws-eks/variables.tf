variable "name" {
  type = string
}
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
  default = {
} }

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "Subnets for the EKS control plane (at least 2 AZs)."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the cluster security group."
  type        = string
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the public endpoint."
  type        = list(string)
  default     = []
}

variable "cluster_security_group_ids" {
  description = "Additional security group IDs to attach to the cluster."
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "Control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log group retention for cluster logs."
  type        = number
  default     = 90
}

variable "cluster_log_kms_key_id" {
  description = "KMS key for CloudWatch log group encryption."
  type        = string
  default     = null
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN for Kubernetes secret envelope encryption."
  type        = string
  default     = null
}

variable "cluster_role_arn" {
  description = "ARN of an existing cluster IAM role. Leave empty to auto-create."
  type        = string
  default     = null
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs."
  type        = string
  default     = "172.20.0.0/16"
}

variable "ip_family" {
  description = "ipv4 or ipv6."
  type        = string
  default     = "ipv4"
}

# ---------------------------------------------------------------------------
# Managed Node Groups
# ---------------------------------------------------------------------------
variable "node_groups" {
  description = "Map of managed node group configurations."
  type = map(object({
    ami_type        = optional(string, "AL2_x86_64")
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "ON_DEMAND")
    disk_size       = optional(number, 50)
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 5)
    max_unavailable = optional(number, 1)
    subnet_ids      = optional(list(string), [])
    labels          = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, null)
      effect = string
    })), [])
    kms_key_arn           = optional(string, null)
    launch_template_id    = optional(string, null)
    launch_template_version = optional(string, null)
  }))
  default = {}
}

variable "node_groups_default_subnet_ids" {
  description = "Default subnets for node groups (overridden per group if set)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Fargate
# ---------------------------------------------------------------------------
variable "fargate_profiles" {
  description = "Map of Fargate profile configurations."
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    subnet_ids = optional(list(string), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Add-ons
# ---------------------------------------------------------------------------
variable "cluster_addons" {
  description = "Map of cluster add-ons to enable."
  type = map(object({
    addon_version               = optional(string, null)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string, null)
    configuration_values        = optional(string, null)
  }))
  default = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
    aws-ebs-csi-driver = {}
  }
}

# ---------------------------------------------------------------------------
# OIDC / IRSA
# ---------------------------------------------------------------------------
variable "enable_irsa" {
  description = "Create OIDC provider for IAM Roles for Service Accounts."
  type        = bool
  default     = true
}
