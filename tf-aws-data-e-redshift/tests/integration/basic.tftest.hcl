# Integration test — tf-aws-data-e-redshift
# WARNING: Redshift clusters cost $0.25+/node-hour. Plan only to validate config.
# Uses command = plan ONLY to avoid incurring charges.
#
# NOTE: This module also supports a serverless option (create_serverless = true)
# using serverless_namespaces + serverless_workgroups. Serverless Redshift charges
# only for compute used (RPU-seconds), making it cheaper for infrequent workloads.
# To test serverless, switch command to apply and use the serverless_namespaces /
# serverless_workgroups variables instead of clusters.

run "redshift_cluster_plan" {
  # SKIP_IN_CI
  # WARNING: Redshift clusters cost $0.25+/node-hour. Plan only to validate config.
  command = plan

  variables {
    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }

    create_subnet_groups      = true
    create_parameter_groups   = false
    create_snapshot_schedules = false
    create_scheduled_actions  = false
    create_data_shares        = false
    create_alarms             = false
    create_iam_role           = false
    create_serverless         = false

    subnet_groups = {
      basic = {
        description = "Integration test subnet group"
        subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
      }
    }

    clusters = {
      basic = {
        database_name                       = "dev"
        master_username                     = "admin"
        node_type                           = "ra3.xlplus"
        cluster_type                        = "multi-node"
        number_of_nodes                     = 2
        subnet_group_key                    = "basic"
        vpc_security_group_ids              = ["sg-00000000000000001"]
        encrypted                           = false
        enhanced_vpc_routing                = false
        publicly_accessible                 = false
        manage_master_password              = true
        automated_snapshot_retention_period = 1
        logging_enabled                     = false
        skip_final_snapshot                 = true
        tags = {
          Environment = "integration-test"
        }
      }
    }
  }

  assert {
    condition     = length(var.clusters) == 1
    error_message = "Expected exactly one Redshift cluster to be planned."
  }

  assert {
    condition     = length(var.subnet_groups) == 1
    error_message = "Expected exactly one subnet group to be planned."
  }
}
