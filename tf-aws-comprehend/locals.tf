locals {
  # Append a hyphen only when a prefix is given, so names read cleanly
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""

  # Module-level tags merged on top of caller-supplied tags
  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "tf-aws-comprehend"
    }
  )

  # BYO pattern: use the auto-created role when create_iam_role = true,
  # otherwise fall back to the caller-supplied ARN.
  role_arn = var.create_iam_role ? aws_iam_role.comprehend[0].arn : var.role_arn

  # Convenience: collect all unique S3 bucket names referenced across both
  # resource types so the IAM inline policy can grant scoped access.
  classifier_s3_uris = flatten([
    for k, v in var.document_classifiers : compact([v.s3_uri, v.test_s3_uri])
  ])

  recognizer_s3_uris = flatten([
    for k, v in var.entity_recognizers : compact([
      try(v.entity_list.s3_uri, null),
      try(v.annotations.s3_uri, null),
      try(v.annotations.test_s3_uri, null),
      try(v.documents.s3_uri, null),
      try(v.documents.test_s3_uri, null),
    ])
  ])

  all_s3_uris = distinct(concat(local.classifier_s3_uris, local.recognizer_s3_uris))

  # Extract bucket names (s3://bucket-name/prefix → bucket-name)
  all_s3_buckets = distinct([
    for uri in local.all_s3_uris :
    regex("^s3://([^/]+)", uri)[0]
  ])

  # Gather every KMS key that might be used so the IAM policy grants access
  all_kms_key_arns = distinct(compact(concat(
    [var.kms_key_arn, var.volume_kms_key_arn],
    [for k, v in var.document_classifiers : v.model_kms_key_id],
    [for k, v in var.document_classifiers : v.volume_kms_key_id],
    [for k, v in var.entity_recognizers : v.model_kms_key_id],
    [for k, v in var.entity_recognizers : v.volume_kms_key_id],
  )))

  kms_enabled = length(local.all_kms_key_arns) > 0
}
