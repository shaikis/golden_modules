# ===========================================================================
# INTERFACE ENDPOINTS (SSM, EC2, Secrets Manager, KMS, ECR, etc.)
# ===========================================================================
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = can(regex("^com\\.amazonaws\\.", each.value.service_name)) ? each.value.service_name : "com.amazonaws.${local.region}.${each.value.service_name}"
  subnet_ids          = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.default_subnet_ids
  security_group_ids  = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : var.default_security_group_ids
  private_dns_enabled = each.value.private_dns
  ip_address_type     = each.value.ip_address_type
  policy              = each.value.policy

  tags = merge(local.tags, { Name = "${local.name}-ep-${each.key}" })
}
