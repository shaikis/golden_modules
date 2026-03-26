# =============================================================================
# EKS AI-Powered Incident Response — outputs.tf
# =============================================================================

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Map of AZ => private subnet ID."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Map of AZ => public subnet ID."
  value       = module.vpc.public_subnet_ids
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the cluster."
  value       = module.eks.cluster_version
}

output "kubeconfig_command" {
  description = "AWS CLI command to update the local kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ---------------------------------------------------------------------------
# AMP (Amazon Managed Prometheus)
# ---------------------------------------------------------------------------

output "amp_workspace_id" {
  description = "ID of the AMP workspace."
  value       = module.amp.workspace_id
}

output "amp_workspace_arn" {
  description = "ARN of the AMP workspace."
  value       = module.amp.workspace_arn
}

output "amp_remote_write_url" {
  description = "Remote write URL for Prometheus / ADOT configuration."
  value       = module.amp.remote_write_url
}

output "amp_query_url" {
  description = "Query URL for Grafana or other visualization tools."
  value       = module.amp.query_url
}

output "amp_irsa_role_arn" {
  description = "ARN of the IRSA role that allows in-cluster workloads to remote_write to AMP."
  value       = module.amp.irsa_role_arn
}

# ---------------------------------------------------------------------------
# CloudWatch
# ---------------------------------------------------------------------------

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for AMP (EKS logs are managed by the EKS module)."
  value       = module.amp.log_group_name
}

# ---------------------------------------------------------------------------
# KMS
# ---------------------------------------------------------------------------

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key. Null when enable_kms = false."
  value       = local.kms_key_arn
}

# ---------------------------------------------------------------------------
# AWS DevOps Agent
# ---------------------------------------------------------------------------

output "devops_agent_space_id" {
  description = "ID of the provisioned AWS DevOps Agent Space. Empty when enable_devops_agent = false."
  value       = var.enable_devops_agent ? module.devops_agent[0].stack_outputs["agent_space_id"] : null
}

output "devops_agent_console_url" {
  description = "URL to open the AWS DevOps Agent console in the target region."
  value       = "https://${var.aws_region}.console.aws.amazon.com/aidevops/home?region=${var.aws_region}"
}
