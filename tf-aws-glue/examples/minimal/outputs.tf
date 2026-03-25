output "job_arns" {
  value = module.glue.job_arns
}

output "job_names" {
  value = module.glue.job_names
}

output "glue_service_role_arn" {
  value = module.glue.glue_service_role_arn
}
