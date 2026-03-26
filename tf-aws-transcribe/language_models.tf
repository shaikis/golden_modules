resource "aws_transcribe_language_model" "this" {
  for_each = var.create_language_models ? var.language_models : {}

  model_name      = "${local.name_prefix}${each.key}"
  language_code   = each.value.language_code
  base_model_name = each.value.base_model_name

  input_data_config {
    s3_uri               = each.value.s3_uri
    tuning_data_s3_uri   = each.value.tuning_data_s3_uri
    data_access_role_arn = local.role_arn
  }

  tags = merge(local.tags, each.value.tags)
}
