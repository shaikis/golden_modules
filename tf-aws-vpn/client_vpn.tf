# ===========================================================================
# CLIENT VPN
# ===========================================================================

# ---------------------------------------------------------------------------
# CloudWatch Log Group for Client VPN
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "client_vpn" {
  count = var.enable_client_vpn ? 1 : 0

  name              = coalesce(var.client_vpn_cloudwatch_log_group, "/aws/vpn/client/${local.name}")
  retention_in_days = var.client_vpn_log_retention_days

  tags = local.tags
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  count          = var.enable_client_vpn ? 1 : 0
  name           = "${local.name}-connections"
  log_group_name = aws_cloudwatch_log_group.client_vpn[0].name
}

# ---------------------------------------------------------------------------
# Client VPN Endpoint
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_endpoint" "this" {
  count = var.enable_client_vpn ? 1 : 0

  description            = "${local.name} Client VPN"
  server_certificate_arn = var.client_vpn_server_cert_arn
  client_cidr_block      = var.client_vpn_cidr
  split_tunnel           = var.client_vpn_split_tunnel
  transport_protocol     = var.client_vpn_transport_protocol
  vpn_port               = var.client_vpn_vpn_port
  session_timeout_hours  = var.client_vpn_session_timeout_hours
  vpc_id                 = var.client_vpn_vpc_id
  security_group_ids     = var.client_vpn_security_group_ids
  dns_servers            = var.client_vpn_dns_servers
  self_service_portal    = "enabled"

  # Authentication: mutual TLS
  dynamic "authentication_options" {
    for_each = var.client_vpn_root_cert_chain_arn != null ? [1] : []
    content {
      type                       = "certificate-authentication"
      root_certificate_chain_arn = var.client_vpn_root_cert_chain_arn
    }
  }

  # Authentication: federated (SAML/SSO)
  dynamic "authentication_options" {
    for_each = var.client_vpn_saml_provider_arn != null ? [1] : []
    content {
      type                           = "federated-authentication"
      saml_provider_arn              = var.client_vpn_saml_provider_arn
      self_service_saml_provider_arn = var.client_vpn_self_service_saml_provider_arn
    }
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn[0].name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn[0].name
  }

  tags = merge(local.tags, { Name = "${local.name}-client-vpn" })
}

# ---------------------------------------------------------------------------
# Network Associations (subnets)
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_network_association" "this" {
  for_each = var.enable_client_vpn ? toset(var.client_vpn_subnet_ids) : []

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  subnet_id              = each.value
}

# ---------------------------------------------------------------------------
# Authorization Rules
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_authorization_rule" "this" {
  for_each = var.enable_client_vpn ? var.client_vpn_authorization_rules : {}

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  target_network_cidr    = each.value.target_network_cidr
  access_group_id        = each.value.access_group_id
  authorize_all_groups   = each.value.authorize_all_groups
  description            = each.value.description
}

# ---------------------------------------------------------------------------
# Additional Routes
# ---------------------------------------------------------------------------
resource "aws_ec2_client_vpn_route" "this" {
  for_each = var.enable_client_vpn ? var.client_vpn_additional_routes : {}

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  destination_cidr_block = each.value.destination_cidr
  target_vpc_subnet_id   = each.value.target_vpc_subnet_id
  description            = each.value.description

  depends_on = [aws_ec2_client_vpn_network_association.this]
}
