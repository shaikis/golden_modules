############################################
# BACKUP FRAMEWORK
############################################
resource "aws_backup_framework" "this" {
  count = var.create_framework ? 1 : 0

  name        = "${local.name_prefix}-framework"
  description = var.framework_description

  dynamic "control" {
    for_each = var.framework_controls
    content {
      name = control.value.name

      dynamic "input_parameter" {
        for_each = control.value.input_parameters
        content {
          name  = input_parameter.value.name
          value = input_parameter.value.value
        }
      }
    }
  }

  tags = local.common_tags
}

############################################
# REPORT PLANS
############################################
resource "aws_backup_report_plan" "this" {
  for_each = var.report_plans

  name        = "${local.name_prefix}-${each.key}"
  description = each.value.description

  report_delivery_channel {
    s3_bucket_name = each.value.s3_bucket_name
    s3_key_prefix  = each.value.s3_key_prefix
    formats        = each.value.formats
  }

  report_setting {
    report_template = each.value.report_template
  }

  tags = merge(local.common_tags, each.value.tags)
}
