module "prefix_lists" {
  source = "./modules/prefix-list"

  for_each = var.prefix_lists

  name           = each.value.name
  address_family = each.value.address_family
  max_entries    = each.value.max_entries
  entries        = each.value.entries
  tags           = each.value.tags
  environment    = var.environment
}