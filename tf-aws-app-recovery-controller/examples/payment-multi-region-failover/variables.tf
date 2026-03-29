variable "name"        { type = string; default = "acme-pay" }
variable "environment" { type = string; default = "prod" }
variable "project"     { type = string; default = "realtime-payments" }
variable "owner"       { type = string; default = "payments-sre" }
variable "cost_center" { type = string; default = "CC-PAYMENTS" }

variable "hosted_zone_name"  { type = string; description = "Route 53 hosted zone (e.g. payments.acme.com)" }
variable "api_subdomain"     { type = string; default = "api"; description = "API subdomain prefix" }

variable "cloudfront_domain_name_primary"  { type = string; description = "Primary CloudFront domain (us-east-1)" }
variable "cloudfront_domain_name_failover" { type = string; description = "Failover CloudFront domain (us-west-2)" }

variable "msk_primary_cluster_arn"  { type = string }
variable "msk_failover_cluster_arn" { type = string }

variable "dynamodb_payments_table_arn_primary"  { type = string }
variable "dynamodb_payments_table_arn_failover" { type = string }

variable "lambda_initiator_arn_primary"  { type = string }
variable "lambda_initiator_arn_failover" { type = string }
