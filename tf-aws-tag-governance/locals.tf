locals {
  name_prefix = trim(join("-", compact([var.name_prefix, var.name])), "-")

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "tf-aws-tag-governance"
  })

  ordered_required_tags = [
    for key in sort(keys(var.required_tags)) : {
      key   = key
      value = try(var.required_tags[key].value, null)
    }
  ]

  required_tags_input_parameters = merge(
    length(local.ordered_required_tags) > 0 ? {
      tag1Key = local.ordered_required_tags[0].key
    } : {},
    length(local.ordered_required_tags) > 0 && local.ordered_required_tags[0].value != null ? {
      tag1Value = local.ordered_required_tags[0].value
    } : {},
    length(local.ordered_required_tags) > 1 ? {
      tag2Key = local.ordered_required_tags[1].key
    } : {},
    length(local.ordered_required_tags) > 1 && local.ordered_required_tags[1].value != null ? {
      tag2Value = local.ordered_required_tags[1].value
    } : {},
    length(local.ordered_required_tags) > 2 ? {
      tag3Key = local.ordered_required_tags[2].key
    } : {},
    length(local.ordered_required_tags) > 2 && local.ordered_required_tags[2].value != null ? {
      tag3Value = local.ordered_required_tags[2].value
    } : {},
    length(local.ordered_required_tags) > 3 ? {
      tag4Key = local.ordered_required_tags[3].key
    } : {},
    length(local.ordered_required_tags) > 3 && local.ordered_required_tags[3].value != null ? {
      tag4Value = local.ordered_required_tags[3].value
    } : {},
    length(local.ordered_required_tags) > 4 ? {
      tag5Key = local.ordered_required_tags[4].key
    } : {},
    length(local.ordered_required_tags) > 4 && local.ordered_required_tags[4].value != null ? {
      tag5Value = local.ordered_required_tags[4].value
    } : {},
    length(local.ordered_required_tags) > 5 ? {
      tag6Key = local.ordered_required_tags[5].key
    } : {},
    length(local.ordered_required_tags) > 5 && local.ordered_required_tags[5].value != null ? {
      tag6Value = local.ordered_required_tags[5].value
    } : {}
  )

  effective_sns_topic_arn = coalesce(
    var.sns_topic_arn,
    try(aws_sns_topic.this[0].arn, null)
  )

  effective_config_role_arn = coalesce(
    var.config_role_arn,
    try(aws_iam_role.config[0].arn, null)
  )
}
