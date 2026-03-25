resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name         = var.dhcp_options_domain_name
  domain_name_servers = var.dhcp_options_domain_name_servers
  ntp_servers         = var.dhcp_options_ntp_servers

  tags = merge(local.tags, { Name = "${local.name}-dhcp-opts" })
}

resource "aws_vpc_dhcp_options_association" "this" {
  count           = var.enable_dhcp_options ? 1 : 0
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}
