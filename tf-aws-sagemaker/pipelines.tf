resource "aws_sagemaker_pipeline" "this" {
  for_each = var.create_pipelines ? var.pipelines : {}

  pipeline_name        = "${local.name_prefix}${each.key}"
  pipeline_description = each.value.description
  role_arn             = local.role_arn

  pipeline_definition = each.value.pipeline_definition

  tags = merge(local.tags, each.value.tags)
}
