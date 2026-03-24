# ---------------------------------------------------------------------------
# Glue Connections
# ---------------------------------------------------------------------------

resource "aws_glue_connection" "this" {
  for_each = var.create_connections ? var.connections : {}

  name            = "${var.name_prefix}${each.key}"
  description     = each.value.description
  connection_type = each.value.connection_type != null ? each.value.connection_type : "JDBC"
  match_criteria  = each.value.match_criteria != null ? each.value.match_criteria : []

  connection_properties = each.value.connection_properties

  dynamic "physical_connection_requirements" {
    for_each = (
      each.value.subnet_id != null ||
      (each.value.security_group_ids != null && length(each.value.security_group_ids) > 0)
    ) ? [1] : []
    content {
      subnet_id              = each.value.subnet_id
      security_group_id_list = each.value.security_group_ids != null ? each.value.security_group_ids : []
      availability_zone      = each.value.availability_zone
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}${each.key}" })
}
