output "nlb_dns_name" {
  value = module.nlb.lb_dns_name
}

output "target_group_arns" {
  value = module.nlb.target_group_arns
}
