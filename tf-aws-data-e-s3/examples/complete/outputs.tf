output "bucket_arn" { value = module.s3.bucket_arn }
output "bucket_id" { value = module.s3.bucket_id }
output "bucket_regional_domain_name" { value = module.s3.bucket_regional_domain_name }
output "log_bucket_id" { value = module.s3_logs.bucket_id }
output "kms_key_arn" { value = module.kms.key_arn }
