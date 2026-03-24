variable "endpoint_accesses" {
  description = "Map of Redshift managed VPC endpoint access configurations."
  type = map(object({
    cluster_key            = optional(string, null)
    cluster_identifier     = optional(string, null)
    endpoint_name          = optional(string, null)
    subnet_group_name      = optional(string, null)
    vpc_security_group_ids = optional(list(string), [])
    resource_owner         = optional(string, null)
  }))
  default = {}
}

resource "aws_redshift_endpoint_access" "this" {
  for_each = var.endpoint_accesses

  cluster_identifier = (
    each.value.cluster_key != null
    ? aws_redshift_cluster.this[each.value.cluster_key].cluster_identifier
    : each.value.cluster_identifier
  )
  endpoint_name          = coalesce(each.value.endpoint_name, each.key)
  subnet_group_name      = each.value.subnet_group_name
  vpc_security_group_ids = each.value.vpc_security_group_ids
  resource_owner         = each.value.resource_owner
}
