resource "aws_msk_configuration" "this" {
  for_each = var.configurations

  name           = each.value.name
  description    = each.value.description
  kafka_versions = each.value.kafka_versions

  server_properties = each.value.server_properties != null ? each.value.server_properties : join("\n", [
    for k, v in local.default_server_properties : "${k}=${v}"
  ])
}
