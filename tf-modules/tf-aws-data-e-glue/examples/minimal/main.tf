# Minimal Glue setup — one ETL job with auto-created IAM role.
# No crawlers, triggers, workflows, connections, or schema registries.
# Add feature flags incrementally as your pipeline grows.

module "glue" {
  source = "../../"

  # Auto-create the Glue service IAM role (default: true)
  create_iam_role = true

  data_lake_bucket_arns = ["arn:aws:s3:::my-datalake-bucket"]

  jobs = {
    transform_data = {
      script_location   = "s3://my-scripts-bucket/etl/transform.py"
      glue_version      = "4.0"
      worker_type       = "G.1X"
      number_of_workers = 2
    }
  }

  # Everything else is disabled by default:
  # create_catalog_databases       = false  (default)
  # create_crawlers                = false  (default)
  # create_triggers                = false  (default)
  # create_workflows               = false  (default)
  # create_connections             = false  (default)
  # create_schema_registries       = false  (default)
  # create_security_configurations = false  (default)
}

output "job_arns" {
  value = module.glue.job_arns
}

output "glue_role_arn" {
  value = module.glue.glue_service_role_arn
}
