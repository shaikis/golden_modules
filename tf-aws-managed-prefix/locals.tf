locals {
  # 1. Normalize input
  cleaned_entries = [
    for cidr in var.entries_list :
    trim(cidr)
  ]

  # 2. Remove duplicates ✅
  unique_entries = distinct(local.cleaned_entries)

  # 3. Sort for deterministic plans ✅
  sorted_entries = sort(local.unique_entries)

  # 4. Convert to map (stable keys)
  final_entries = {
    for idx, cidr in local.sorted_entries :
    "entry-${idx}" => {
      cidr        = cidr
      description = null
    }
  }

  # 5. Auto max_entries ✅
  max_entries = max(length(local.final_entries), 1)

  standard_tags = merge(
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Module      = "prefix-list"
    },
    var.tags
  )
}