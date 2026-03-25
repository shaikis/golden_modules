# Unit tests — tf-aws-glue variable validation
# command = plan: no real AWS resources are created.

run "valid_worker_type_g1x_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    jobs = {
      etl_job = {
        script_location = "s3://my-bucket/scripts/job.py"
        worker_type     = "G.1X"
      }
    }
  }

  assert {
    condition     = var.jobs["etl_job"].worker_type == "G.1X"
    error_message = "Expected worker_type G.1X to be accepted."
  }
}

run "valid_worker_type_g2x_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    jobs = {
      etl_job = {
        script_location = "s3://my-bucket/scripts/job.py"
        worker_type     = "G.2X"
      }
    }
  }

  assert {
    condition     = var.jobs["etl_job"].worker_type == "G.2X"
    error_message = "Expected worker_type G.2X to be accepted."
  }
}

run "job_defaults_are_sensible" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    jobs = {
      my_job = {
        script_location = "s3://my-bucket/scripts/job.py"
      }
    }
  }

  assert {
    condition     = var.jobs["my_job"].glue_version == "4.0"
    error_message = "Expected glue_version to default to 4.0."
  }

  assert {
    condition     = var.jobs["my_job"].worker_type == "G.1X"
    error_message = "Expected worker_type to default to G.1X."
  }

  assert {
    condition     = var.jobs["my_job"].number_of_workers == 2
    error_message = "Expected number_of_workers to default to 2."
  }

  assert {
    condition     = var.jobs["my_job"].max_retries == 1
    error_message = "Expected max_retries to default to 1."
  }
}

run "catalog_database_with_description_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_catalog_databases = true
    catalog_databases = {
      analytics = {
        description = "Analytics data lake database"
      }
    }
  }

  assert {
    condition     = length(var.catalog_databases) == 1
    error_message = "Expected one catalog database definition to be accepted."
  }
}

run "name_prefix_empty_string_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = ""
  }

  assert {
    condition     = var.name_prefix == ""
    error_message = "Expected name_prefix to accept an empty string."
  }
}
