# ===========================================================================
# NETWORK
# ===========================================================================
output "vpc_id"                  { value = module.vpc.vpc_id }
output "private_subnet_ids"      { value = module.vpc.private_subnet_ids_list }

# ===========================================================================
# CLOUDFRONT / API
# ===========================================================================
output "cloudfront_distribution_id"     { value = module.cloudfront.distribution_id }
output "cloudfront_domain_name"         { value = module.cloudfront.distribution_domain_name }
output "payment_api_url" {
  description = "Payment API endpoint — use this as the integration URL for partner banks."
  value       = "https://${module.cloudfront.distribution_domain_name}/v1/payments"
}
output "api_gateway_id"                 { value = module.api_gateway.api_id }

# ===========================================================================
# MSK
# ===========================================================================
output "msk_cluster_arn"                { value = module.msk.cluster_arns["payments"] }
output "msk_bootstrap_brokers_sasl_iam" { value = module.msk.cluster_bootstrap_brokers_sasl_iam["payments"] }
output "msk_replicator_arns"            { value = module.msk.replicator_arns }

# ===========================================================================
# DYNAMODB
# ===========================================================================
output "dynamodb_payments_table"     { value = module.dynamodb.table_names["payments"] }
output "dynamodb_idempotency_table"  { value = module.dynamodb.table_names["idempotency"] }
output "dynamodb_ledger_table"       { value = module.dynamodb.table_names["ledger"] }
output "dynamodb_audit_table"        { value = module.dynamodb.table_names["audit-trail"] }

# ===========================================================================
# LAMBDA ARNS
# ===========================================================================
output "lambda_arns" {
  description = "Map of microservice name → Lambda ARN."
  value = {
    payment-initiator = module.lambda_payment_initiator.function_arn
    payment-validator = module.lambda_payment_validator.function_arn
    risk-management   = module.lambda_risk_management.function_arn
    payment-executor  = module.lambda_payment_executor.function_arn
    settlement        = module.lambda_settlement.function_arn
    notification      = module.lambda_notification.function_arn
  }
}

# ===========================================================================
# SECURITY
# ===========================================================================
output "waf_web_acl_arn"       { value = module.waf.web_acl_arn }
output "kms_key_arn"           { value = module.kms.key_arn }
output "dlq_arn"               { value = module.sqs_dlq.queue_arn }
output "alarm_sns_topic_arn"   { value = module.alarms_sns.topic_arn }
output "notification_topic_arn" { value = module.payment_notifications_sns.topic_arn }
