# tests/integration/basic.tftest.hcl
# SKIP_IN_CI
#
# WARNING: MWAA environments are EXPENSIVE (~$0.49+/hour for mw1.small).
# This test uses command = plan ONLY to avoid incurring real charges.
# Do NOT change to command = apply without understanding the cost impact.
#
# Validates that a complete MWAA environment definition passes Terraform plan
# with required networking inputs provided.

run "mwaa_environment_plan_only_cost_warning" {
  command = plan

  variables {
    create_alarms   = false
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test"

    environments = {
      test_env = {
        airflow_version    = "2.8.1"
        environment_class  = "mw1.small"
        max_workers        = 1
        min_workers        = 1
        schedulers         = 2

        source_bucket_arn  = "arn:aws:s3:::my-mwaa-dags-bucket"
        dag_s3_path        = "dags/"
        execution_role_arn = "arn:aws:iam::123456789012:role/test"

        webserver_access_mode = "PRIVATE_ONLY"

        subnet_ids         = ["subnet-00000000000000001", "subnet-00000000000000002"]
        security_group_ids = ["sg-00000000000000001"]

        tags = {
          Environment = "test"
          ManagedBy   = "terraform-test"
        }
      }
    }

    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
  }

  module {
    source = "../../"
  }
}
