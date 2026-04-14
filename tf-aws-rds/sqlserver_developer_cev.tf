data "aws_region" "current" {}

resource "null_resource" "sqlserver_developer_custom_engine_version" {
  count = var.create_sqlserver_developer_custom_engine_version ? 1 : 0

  triggers = {
    region                = data.aws_region.current.name
    engine                = var.engine
    engine_version        = var.sqlserver_developer_custom_engine_version_name
    bucket_name           = coalesce(var.sqlserver_developer_media_bucket_name, "")
    bucket_prefix         = coalesce(var.sqlserver_developer_media_bucket_prefix, "")
    media_files_json      = jsonencode(var.sqlserver_developer_media_files)
    description           = coalesce(var.sqlserver_developer_custom_engine_version_description, "")
    poll_interval_seconds = tostring(var.sqlserver_developer_wait_poll_interval_seconds)
    timeout_seconds       = tostring(var.sqlserver_developer_wait_timeout_seconds)
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${path.module}/scripts/create-sqlserver-developer-cev.ps1"

    environment = {
      AWS_REGION           = self.triggers.region
      CEV_ENGINE           = self.triggers.engine
      CEV_ENGINE_VERSION   = self.triggers.engine_version
      CEV_BUCKET_NAME      = self.triggers.bucket_name
      CEV_BUCKET_PREFIX    = self.triggers.bucket_prefix
      CEV_MEDIA_FILES_JSON = self.triggers.media_files_json
      CEV_DESCRIPTION      = self.triggers.description
      CEV_POLL_INTERVAL    = self.triggers.poll_interval_seconds
      CEV_TIMEOUT_SECONDS  = self.triggers.timeout_seconds
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${path.module}/scripts/delete-sqlserver-developer-cev.ps1"

    environment = {
      AWS_REGION         = self.triggers.region
      CEV_ENGINE         = self.triggers.engine
      CEV_ENGINE_VERSION = self.triggers.engine_version
    }
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.engine == "sqlserver-dev-ee"
      error_message = "create_sqlserver_developer_custom_engine_version requires engine = \"sqlserver-dev-ee\"."
    }

    precondition {
      condition     = var.sqlserver_developer_custom_engine_version_name != null
      error_message = "Set sqlserver_developer_custom_engine_version_name when create_sqlserver_developer_custom_engine_version = true."
    }

    precondition {
      condition     = var.sqlserver_developer_media_bucket_name != null
      error_message = "Set sqlserver_developer_media_bucket_name when create_sqlserver_developer_custom_engine_version = true."
    }

    precondition {
      condition     = length(var.sqlserver_developer_media_files) >= 2
      error_message = "Provide at least the SQL Server Developer ISO and one cumulative update EXE in sqlserver_developer_media_files."
    }
  }
}
