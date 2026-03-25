output "cluster_id" { value = aws_eks_cluster.this.id }
output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_arn" { value = aws_eks_cluster.this.arn }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca_certificate" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}
output "cluster_version" { value = aws_eks_cluster.this.version }
output "cluster_security_group_id" { value = aws_security_group.cluster.id }
output "cluster_role_arn" { value = length(aws_iam_role.cluster) > 0 ? aws_iam_role.cluster[0].arn : var.cluster_role_arn }
output "node_group_role_arn" { value = length(aws_iam_role.node_group) > 0 ? aws_iam_role.node_group[0].arn : null }
output "oidc_provider_arn" { value = length(aws_iam_openid_connect_provider.this) > 0 ? aws_iam_openid_connect_provider.this[0].arn : null }
output "oidc_provider_url" { value = length(aws_iam_openid_connect_provider.this) > 0 ? aws_iam_openid_connect_provider.this[0].url : null }
output "node_groups" { value = { for k, v in aws_eks_node_group.this : k => v.id } }
