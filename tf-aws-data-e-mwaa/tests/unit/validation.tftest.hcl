# tests/unit/validation.tftest.hcl
# Verifies that invalid airflow_version and environment_class values are
# rejected by module input validation.

run "invalid_airflow_version_rejected" {
  command = plan

  variables {
    create_alarms   = false
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test"

    environments = {
      bad_version = {
        # Not a valid MWAA Airflow version — must be rejected by validation.
        airflow_version    = "1.0.0"
        source_bucket_arn  = "arn:aws:s3:::my-mwaa-bucket"
        dag_s3_path        = "dags/"
        subnet_ids         = ["subnet-00000000000000001", "subnet-00000000000000002"]
        security_group_ids = ["sg-00000000000000001"]
      }
    }
  }

  module {
    source = "../../"
  }

  expect_failures = [
    var.environments,
  ]
}

run "invalid_environment_class_rejected" {
  command = plan

  variables {
    create_alarms   = false
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test"

    environments = {
      bad_class = {
        airflow_version    = "2.8.1"
        # Not a valid MWAA environment class — must be rejected by validation.
        environment_class  = "mw1.invalid"
        source_bucket_arn  = "arn:aws:s3:::my-mwaa-bucket"
        dag_s3_path        = "dags/"
        subnet_ids         = ["subnet-00000000000000001", "subnet-00000000000000002"]
        security_group_ids = ["sg-00000000000000001"]
      }
    }
  }

  module {
    source = "../../"
  }

  expect_failures = [
    var.environments,
  ]
}
