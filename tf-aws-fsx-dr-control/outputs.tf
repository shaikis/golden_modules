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
  description = "Example Step Functions input for a planned non-promoting switchover."
  value = {
    operation = "switchover"
    ontap_actions = [
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:primary-fsxadmin"
        method            = "GET"
        path              = "/api/snapmirror/relationships/{relationship-uuid}"
        expected_statuses = [200]
        validate_certs    = false
      },
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:dr-fsxadmin"
        method            = "GET"
        path              = "/api/storage/volumes/{dr-volume-uuid}"
        query             = { fields = "name,state,style,nas.path,svm" }
        expected_statuses = [200]
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
        active_site      = "dr"
        mode             = "switchover"
        promoted         = false
        revert_supported = true
      }
    }
    notification = {
      action  = "notify"
      subject = "FSx ONTAP switchover complete"
      message = "Planned switchover completed without promoting the DR volume."
    }
  }
}

output "revert_switchover_execution_example" {
  description = "Example Step Functions input for reversing a planned switchover."
  value = {
    operation = "revert_switchover"
    ontap_actions = [
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:primary-fsxadmin"
        method            = "GET"
        path              = "/api/storage/volumes/{primary-volume-uuid}"
        query             = { fields = "name,state,nas.path,svm" }
        expected_statuses = [200]
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
        mode        = "revert_switchover"
      }
    }
    notification = {
      action  = "notify"
      subject = "FSx ONTAP switchover reverted"
      message = "Client access was moved back to the primary site."
    }
  }
}

output "failover_execution_example" {
  description = "Example Step Functions input for emergency failover that promotes the DR side."
  value = {
    operation = "failover"
    ontap_actions = [
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:dr-fsxadmin"
        method            = "POST"
        path              = "/api/snapmirror/relationships/{relationship-uuid}/break"
        expected_statuses = [200, 202]
        validate_certs    = false
      },
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:dr-fsxadmin"
        method            = "GET"
        path              = "/api/storage/volumes/{dr-volume-uuid}"
        query             = { fields = "name,state,nas.path,svm" }
        expected_statuses = [200]
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
        mode        = "failover"
        promoted    = true
      }
    }
    notification = {
      action  = "notify"
      subject = "FSx ONTAP failover complete"
      message = "DR site was promoted for emergency service restoration."
    }
  }
}

output "failback_execution_example" {
  description = "Example Step Functions input for failback or reprotect after region recovery."
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
      },
      {
        action            = "ontap_rest"
        secret_arn        = "arn:aws:secretsmanager:region:account:secret:primary-fsxadmin"
        method            = "GET"
        path              = "/api/storage/volumes/{primary-volume-uuid}"
        query             = { fields = "name,state,nas.path,svm" }
        expected_statuses = [200]
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
    notification = {
      action  = "notify"
      subject = "FSx ONTAP failback complete"
      message = "Primary site is active again after recovery and reprotection."
    }
  }
}
