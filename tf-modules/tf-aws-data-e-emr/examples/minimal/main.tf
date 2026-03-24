# Minimal example — one transient Spark cluster that auto-terminates after the job step completes.

module "emr" {
  source = "../../"

  create_iam_role = true

  clusters = {
    "spark-transient-job" = {
      release_label = "emr-7.0.0"
      applications  = ["Spark"]
      subnet_id     = "subnet-0123456789abcdef0"
      log_uri       = "s3://my-emr-logs-bucket/logs/"

      master_instance_type = "m5.xlarge"
      core_instance_type   = "m5.xlarge"
      core_instance_count  = 2

      keep_alive             = false
      termination_protection = false
      idle_timeout_seconds   = 3600

      steps = [
        {
          name              = "run-pyspark-etl"
          action_on_failure = "TERMINATE_CLUSTER"
          hadoop_jar        = "command-runner.jar"
          hadoop_jar_args = [
            "spark-submit",
            "--deploy-mode", "cluster",
            "s3://my-scripts-bucket/etl/transform.py",
            "--input", "s3://my-data-bucket/raw/",
            "--output", "s3://my-data-bucket/processed/"
          ]
        }
      ]

      tags = {
        Environment = "dev"
        JobType     = "transient-etl"
      }
    }
  }

  tags = {
    Project   = "data-platform"
    ManagedBy = "terraform"
  }
}
