provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-ebs"
  environment = var.environment
}

module "ebs" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  kms_key_arn = module.kms.key_arn

  volumes            = var.volumes
  volume_attachments = var.volume_attachments

  enable_dlm      = var.enable_dlm
  dlm_target_tags = var.dlm_target_tags
  dlm_schedules   = var.dlm_schedules

  name_prefix = ""
  tags        = ""
}

output "volume_ids" { value = module.ebs.volume_ids }
output "dlm_policy_id" { value = module.ebs.dlm_policy_id }
