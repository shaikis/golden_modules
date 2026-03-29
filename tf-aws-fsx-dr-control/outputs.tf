output "state_machine_arn" {
  description = "Step Functions state machine ARN for DR operations."
  value       = aws_sfn_state_machine.dr_control.arn
}

output "controller_lambda_arn" {
  description = "Lambda ARN used by the DR workflow."
  value       = aws_lambda_function.controller.arn
}

output "state_table_name" {
  description = "DynamoDB table used to store DR state, if enabled."
  value       = local.state_table_name
}

output "switchover_execution_example" {
  description = "Example Step Functions input for a planned switchover."
  value = {
    operation = "switchover"
    ontap_actions = [
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:primary-fsxadmin"
        method            = "POST"
        path              = "/api/snapmirror/relationships/{relationship-uuid}/quiesce"
        expected_statuses = [200, 202]
        validate_certs    = false
      },
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:dr-fsxadmin"
        method            = "POST"
        path              = "/api/snapmirror/relationships/{relationship-uuid}/break"
        expected_statuses = [200, 202]
        validate_certs    = false
      }
    ]
    dns_change = {
      action  = "update_dns"
      records = ["dr-nfs.example.com"]
    }
    state_record = {
      action       = "record_state"
      workflow_key = "fsx/app"
      attributes = {
        active_site = "dr"
        mode        = "switchover"
      }
    }
    notification = {
      action  = "notify"
      subject = "FSx ONTAP switchover complete"
      message = "DR site is now active."
    }
  }
}

output "failback_execution_example" {
  description = "Example Step Functions input for failback or reprotect."
  value = {
    operation = "failback"
    ontap_actions = [
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:primary-fsxadmin"
        method            = "POST"
        path              = "/api/snapmirror/relationships/{relationship-uuid}/resync"
        expected_statuses = [200, 202]
        validate_certs    = false
      }
    ]
    dns_change = {
      action  = "update_dns"
      records = ["primary-nfs.example.com"]
    }
    state_record = {
      action       = "record_state"
      workflow_key = "fsx/app"
      attributes = {
        active_site = "primary"
        mode        = "failback"
      }
    }
  }
}
