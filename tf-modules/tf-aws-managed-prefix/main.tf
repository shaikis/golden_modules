resource "aws_ec2_managed_prefix_list" "this" {
  name           = var.name
  address_family = var.address_family
  max_entries    = local.max_entries

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true

    ignore_changes = var.allow_replacement ? [] : [
      name,
      address_family
    ]

    # Safety check
    precondition {
      condition     = length(local.final_entries) == length(local.sorted_entries)
      error_message = "Unexpected duplicate handling issue."
    }
  }
}

# ✅ SAFE: separate resources (no replacement risk)
resource "aws_ec2_managed_prefix_list_entry" "this" {
  for_each = local.final_entries

  prefix_list_id = aws_ec2_managed_prefix_list.this.id
  cidr           = each.value.cidr
  description    = each.value.description

  lifecycle {
    create_before_destroy = true
  }
}