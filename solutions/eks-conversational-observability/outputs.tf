# =============================================================================
# Outputs — EKS Conversational Observability
# =============================================================================

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (EKS worker nodes, Lambdas)."
  value       = module.vpc.private_subnet_ids_list
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (load balancers)."
  value       = module.vpc.public_subnet_ids_list
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider (for IRSA)."
  value       = module.eks.oidc_provider_arn
}

output "kubeconfig_command" {
  description = "AWS CLI command to update your local kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# ---------------------------------------------------------------------------
# Kinesis
# ---------------------------------------------------------------------------
output "kinesis_stream_name" {
  description = "Kinesis Data Stream name — use in Fluent Bit OUTPUT configuration."
  value       = module.kinesis.stream_names["telemetry"]
}

output "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN."
  value       = module.kinesis.stream_arns["telemetry"]
}

# ---------------------------------------------------------------------------
# OpenSearch
# ---------------------------------------------------------------------------
output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint — used by both Lambdas."
  value       = module.opensearch.collection_endpoint
}

output "opensearch_collection_arn" {
  description = "OpenSearch Serverless collection ARN."
  value       = module.opensearch.collection_arn
}

output "opensearch_collection_id" {
  description = "OpenSearch Serverless collection ID."
  value       = module.opensearch.collection_id
}

output "opensearch_index_name" {
  description = "Index name where telemetry embeddings are stored."
  value       = var.telemetry_index_name
}

output "opensearch_dashboard_endpoint" {
  description = "OpenSearch Dashboards URL for the serverless collection."
  value       = module.opensearch.dashboard_endpoint
}

# ---------------------------------------------------------------------------
# Lambda
# ---------------------------------------------------------------------------
output "embedding_lambda_name" {
  description = "Name of the telemetry embedding Lambda function."
  value       = module.lambda_embedding.function_name
}

output "embedding_lambda_arn" {
  description = "ARN of the telemetry embedding Lambda function."
  value       = module.lambda_embedding.function_arn
}

output "chatbot_lambda_name" {
  description = "Name of the RAG chatbot Lambda function."
  value       = module.lambda_chatbot.function_name
}

output "chatbot_lambda_arn" {
  description = "ARN of the RAG chatbot Lambda function."
  value       = module.lambda_chatbot.function_arn
}

output "chatbot_lambda_function_url" {
  description = "HTTPS function URL for the chatbot Lambda (AWS_IAM auth)."
  value       = module.lambda_chatbot.function_url
}

# ---------------------------------------------------------------------------
# Bedrock
# ---------------------------------------------------------------------------
output "bedrock_guardrail_id" {
  description = "Bedrock guardrail ID for prompt injection protection. Empty string when enable_bedrock_guardrail = false."
  value       = var.enable_bedrock_guardrail ? module.bedrock.guardrail_ids["observability"] : ""
}

output "bedrock_guardrail_arn" {
  description = "Bedrock guardrail ARN."
  value       = var.enable_bedrock_guardrail ? module.bedrock.guardrail_arns["observability"] : ""
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
output "embedding_lambda_role_arn" {
  description = "IAM role ARN for the embedding Lambda."
  value       = module.iam_embedding_lambda.role_arn
}

output "chatbot_lambda_role_arn" {
  description = "IAM role ARN for the chatbot Lambda."
  value       = module.iam_chatbot_lambda.role_arn
}

# ---------------------------------------------------------------------------
# KMS
# ---------------------------------------------------------------------------
output "kms_key_arn" {
  description = "KMS key ARN used to encrypt all pipeline resources. Null when enable_kms = false."
  value       = local.kms_key_arn
}

# ---------------------------------------------------------------------------
# S3
# ---------------------------------------------------------------------------
output "dlq_bucket_name" {
  description = "S3 bucket name for failed embedding records (DLQ)."
  value       = module.s3_dlq.bucket_name
}

output "dlq_bucket_arn" {
  description = "S3 bucket ARN for failed embedding records (DLQ)."
  value       = module.s3_dlq.bucket_arn
}

# ---------------------------------------------------------------------------
# SNS
# ---------------------------------------------------------------------------
output "alerts_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  value       = module.sns_alerts.topic_arn
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------
output "ecr_embedding_repository_url" {
  description = "ECR repository URL for the embedding Lambda container image."
  value       = module.ecr.repository_urls["embedding-lambda"]
}

output "ecr_chatbot_repository_url" {
  description = "ECR repository URL for the chatbot Lambda container image."
  value       = module.ecr.repository_urls["chatbot-lambda"]
}

# ---------------------------------------------------------------------------
# Fluent Bit hint
# ---------------------------------------------------------------------------
output "fluent_bit_config_hint" {
  description = "Fluent Bit OUTPUT block snippet to paste into fluent-bit-configmap.yaml."
  value       = <<-EOT
    [OUTPUT]
        Name            kinesis_streams
        Match           kube.*
        region          ${var.aws_region}
        stream          ${module.kinesis.stream_names["telemetry"]}
        time_key        time
        time_key_format %Y-%m-%dT%H:%M:%S
  EOT
}

# ---------------------------------------------------------------------------
# Convenience — chatbot invocation example
# ---------------------------------------------------------------------------
output "chatbot_invoke_example" {
  description = "Example AWS CLI command to invoke the chatbot Lambda."
  value       = "aws lambda invoke --function-name ${module.lambda_chatbot.function_name} --payload '{\"query\":\"My pod is stuck in Pending state in namespace prod. Investigate.\"}' --cli-binary-format raw-in-base64-out response.json && cat response.json"
}
