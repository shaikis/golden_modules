# ===========================================================================
# ELASTIC NETWORK INTERFACES
# ===========================================================================
resource "aws_network_interface" "this" {
  for_each = var.network_interfaces

  subnet_id               = each.value.subnet_id
  security_groups         = each.value.security_group_ids
  private_ips             = length(each.value.private_ips) > 0 ? each.value.private_ips : null
  private_ip_list_enabled = each.value.private_ip_list_enabled
  ipv4_prefix_count       = each.value.ipv4_prefix_count
  source_dest_check       = each.value.source_dest_check
  description             = coalesce(each.value.description, "${local.name}-${each.key}")

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" }, each.value.additional_tags)

  lifecycle {
    # Prevent accidental deletion of ENIs attached to running instances
    prevent_destroy = true
    ignore_changes  = [private_ips]
  }
}

# ===========================================================================
# ENI ATTACHMENTS (to EC2 instances)
# ===========================================================================
resource "aws_network_interface_attachment" "this" {
  for_each = {
    for k, v in var.network_interfaces : k => v if v.attachment != null
  }

  network_interface_id = aws_network_interface.this[each.key].id
  instance_id          = each.value.attachment.instance_id
  device_index         = each.value.attachment.device_index
}

# ===========================================================================
# ELASTIC IPs (one per ENI that requests one)
# ===========================================================================
resource "aws_eip" "this" {
  for_each = {
    for k, v in var.network_interfaces : k => v if v.eip != null
  }

  domain                    = each.value.eip.domain
  network_interface         = aws_network_interface.this[each.key].id
  associate_with_private_ip = each.value.eip.associate_with_private_ip

  tags = merge(local.tags, { Name = "${local.name}-${each.key}-eip" })

  depends_on = [aws_network_interface_attachment.this]
}
