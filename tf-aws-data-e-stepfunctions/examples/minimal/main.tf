module "sfn" {
  source = "../../"

  name_prefix = "minimal-"

  state_machines = {
    etl_pipeline = {
      type = "STANDARD"
      definition = jsonencode({
        Comment = "Simple ETL pipeline"
        StartAt = "StartGlueJob"
        States = {
          StartGlueJob = {
            Type     = "Task"
            Resource = "arn:aws:states:::glue:startJobRun.sync"
            Parameters = {
              JobName = "my-etl-job"
            }
            End = true
          }
        }
      })
    }
  }
}
