aws_region  = "us-east-1"
name        = "app/db-password"
environment = "prod"
project     = "my-app"
owner       = "infra-team"
cost_center = "CC-200"
description = "Database password for app (prod)"
tags        = { DataClassification = "Confidential", Compliance = "SOC2" }
