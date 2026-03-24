# ---------------------------------------------------------------------------
# Glue Workflows
# ---------------------------------------------------------------------------

resource "aws_glue_workflow" "this" {
  for_each = var.create_workflows ? var.workflows : {}

  name                   = "${var.name_prefix}${each.key}"
  description            = each.value.description
  default_run_properties = each.value.default_run_properties != null ? each.value.default_run_properties : {}
  max_concurrent_runs    = each.value.max_concurrent_runs != null ? each.value.max_concurrent_runs : 1

  tags = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}${each.key}" })
}
