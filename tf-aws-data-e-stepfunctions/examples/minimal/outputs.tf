output "state_machine_arns" {
  description = "ARNs of created state machines."
  value       = module.sfn.state_machine_arns
}

output "sfn_role_arn" {
  description = "Step Functions execution role ARN."
  value       = module.sfn.sfn_role_arn
}
