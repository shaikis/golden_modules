output "iam_role_arn" { value = module.restore.iam_role_arn }
output "iam_role_name" { value = module.restore.iam_role_name }
output "sns_topic_arn" { value = module.restore.sns_topic_arn }
output "restore_testing_plan_names" { value = module.restore.restore_testing_plan_names }
output "restore_testing_plan_arns" { value = module.restore.restore_testing_plan_arns }
output "restore_testing_selection_names" { value = module.restore.restore_testing_selection_names }
output "restore_guidance" { value = module.restore.restore_guidance }
