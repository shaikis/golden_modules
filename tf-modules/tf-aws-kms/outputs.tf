# ---------------------------------------------------------------------------
# Primary outputs — consumed by tf-aws-glue, tf-aws-kinesis, tf-aws-dynamodb,
# tf-aws-athena, tf-aws-ses, tf-aws-rds, tf-aws-s3, etc.
# ---------------------------------------------------------------------------

output "key_arns" {
  description = "Map of key_name => KMS key ARN. Pass to other modules via kms_key_arn."
  value       = { for k, v in aws_kms_key.this : k => v.arn }
}

output "key_ids" {
  description = "Map of key_name => KMS key ID."
  value       = { for k, v in aws_kms_key.this : k => v.key_id }
}

output "key_aliases" {
  description = "Map of key_name => primary alias name (alias/<name_prefix>/<key_name>)."
  value       = { for k, v in aws_kms_alias.primary : k => v.name }
}

# ---------------------------------------------------------------------------
# Replica key outputs
# ---------------------------------------------------------------------------

output "replica_key_arns" {
  description = "Map of replica_key_name => replica KMS key ARN."
  value       = { for k, v in aws_kms_replica_key.this : k => v.arn }
}

output "replica_key_ids" {
  description = "Map of replica_key_name => replica KMS key ID."
  value       = { for k, v in aws_kms_replica_key.this : k => v.key_id }
}

# ---------------------------------------------------------------------------
# Convenience outputs
# ---------------------------------------------------------------------------

output "all_key_arns" {
  description = "Merged map of all primary + replica key ARNs. Handy for IAM policies that reference all keys."
  value = merge(
    { for k, v in aws_kms_key.this : k => v.arn },
    { for k, v in aws_kms_replica_key.this : "${k}_replica" => v.arn },
  )
}

output "grant_ids" {
  description = "Map of grant_name => grant ID."
  value       = { for k, v in aws_kms_grant.this : k => v.grant_id }
}

output "aws_account_id" {
  description = "AWS account ID in which the keys were created."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region in which the keys were created."
  value       = data.aws_region.current.name
}
