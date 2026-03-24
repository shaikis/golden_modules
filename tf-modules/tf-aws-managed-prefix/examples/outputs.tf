output "prefix_list_ids" {
  value = {
    for k, v in module.prefix_lists :
    k => v.id
  }
}