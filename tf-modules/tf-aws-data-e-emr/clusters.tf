###############################################################################
# EMR Clusters (long-running and transient)
###############################################################################

locals {
  emr_service_role_arn = var.create_iam_role ? aws_iam_role.emr_service[0].arn : var.role_arn
  emr_instance_profile = var.create_iam_role ? aws_iam_instance_profile.emr_ec2[0].arn : var.instance_profile_arn
}

resource "aws_emr_cluster" "this" {
  for_each = var.clusters

  name          = each.key
  release_label = each.value.release_label
  applications  = each.value.applications

  service_role   = local.emr_service_role_arn
  log_uri        = each.value.log_uri
  configurations = each.value.configurations_json

  security_configuration = each.value.security_configuration

  keep_job_flow_alive_when_no_steps = each.value.keep_alive
  termination_protection            = each.value.termination_protection

  ec2_attributes {
    key_name                          = each.value.key_name
    subnet_id                         = each.value.subnet_id
    additional_master_security_groups = length(each.value.additional_master_security_groups) > 0 ? join(",", each.value.additional_master_security_groups) : null
    additional_slave_security_groups  = length(each.value.additional_slave_security_groups) > 0 ? join(",", each.value.additional_slave_security_groups) : null
    instance_profile                  = local.emr_instance_profile
  }

  master_instance_group {
    instance_type = each.value.master_instance_type

    ebs_config {
      size                 = 32
      type                 = "gp3"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    instance_type  = each.value.core_instance_type
    instance_count = each.value.core_instance_count
    bid_price      = each.value.use_spot_for_core ? each.value.core_bid_price : null

    ebs_config {
      size                 = each.value.core_ebs_size
      type                 = each.value.core_ebs_type
      volumes_per_instance = 1
    }
  }

  dynamic "task_instance_group" {
    for_each = each.value.task_instance_type != null && each.value.task_instance_count > 0 ? [1] : []
    content {
      instance_type  = each.value.task_instance_type
      instance_count = each.value.task_instance_count
      bid_price      = each.value.task_bid_price

      ebs_config {
        size                 = 32
        type                 = "gp3"
        volumes_per_instance = 1
      }
    }
  }

  dynamic "bootstrap_action" {
    for_each = each.value.bootstrap_actions
    content {
      name = bootstrap_action.value.name
      path = bootstrap_action.value.path
      args = bootstrap_action.value.args
    }
  }

  dynamic "step" {
    for_each = each.value.steps
    content {
      name              = step.value.name
      action_on_failure = step.value.action_on_failure

      hadoop_jar_step {
        jar        = step.value.hadoop_jar
        args       = step.value.hadoop_jar_args
        main_class = step.value.main_class
        properties = step.value.properties
      }
    }
  }

  dynamic "kerberos_attributes" {
    for_each = each.value.kerberos_realm != null ? [1] : []
    content {
      realm              = each.value.kerberos_realm
      kdc_admin_password = each.value.kerberos_kdc_admin_password
    }
  }

  dynamic "auto_termination_policy" {
    for_each = !each.value.keep_alive && each.value.idle_timeout_seconds != null ? [1] : []
    content {
      idle_timeout = each.value.idle_timeout_seconds
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })

  lifecycle {
    ignore_changes = [
      step,
      configurations,
    ]
  }
}
