# ---------------------------------------------------------------------------
# IAM Role Associations
#
# Links IAM roles to the RDS instance so engine-level features can call
# AWS services directly:
#   Oracle  : S3_INTEGRATION option → query/write S3 from PL/SQL
#   MySQL   : s3Import / s3Export   → LOAD DATA FROM S3 / SELECT INTO OUTFILE S3
#   PostgreSQL: Lambda, SageMaker   → invoke Lambda/SageMaker from SQL
# ---------------------------------------------------------------------------
resource "aws_db_instance_role_association" "this" {
  for_each = var.iam_role_associations

  db_instance_identifier = aws_db_instance.this.id
  feature_name           = each.value.feature_name
  role_arn               = each.value.role_arn
}

# ---------------------------------------------------------------------------
# Snapshot Export to S3 (Parquet format, queryable via Athena)
#
# Supported by: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server
# The export is asynchronous — Terraform starts the task and tracks its
# status. The task continues running in AWS even if Terraform is destroyed.
# ---------------------------------------------------------------------------
resource "aws_rds_export_task" "this" {
  count = var.snapshot_export != null ? 1 : 0

  export_task_identifier = var.snapshot_export.export_task_identifier
  source_arn             = var.snapshot_export.source_arn
  s3_bucket_name         = var.snapshot_export.s3_bucket_name
  s3_prefix              = var.snapshot_export.s3_prefix
  iam_role_arn           = var.snapshot_export.iam_role_arn
  kms_key_id             = var.snapshot_export.kms_key_id
  export_only            = length(var.snapshot_export.export_only) > 0 ? var.snapshot_export.export_only : null
}
