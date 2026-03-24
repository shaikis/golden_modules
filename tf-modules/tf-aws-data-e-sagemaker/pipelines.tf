# ---------------------------------------------------------------------------
# SageMaker Pipelines
# ---------------------------------------------------------------------------

resource "aws_sagemaker_pipeline" "this" {
  for_each = var.create_pipelines ? var.pipelines : {}

  pipeline_name         = each.key
  pipeline_display_name = each.value.display_name != null ? each.value.display_name : each.key
  pipeline_description  = each.value.description
  role_arn              = each.value.role_arn != null ? each.value.role_arn : local.effective_role_arn

  pipeline_definition = each.value.pipeline_definition

  dynamic "parallelism_configuration" {
    for_each = each.value.max_parallel_steps != null ? [1] : []
    content {
      max_parallel_execution_steps = each.value.max_parallel_steps
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}
