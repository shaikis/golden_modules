# Unit tests — defaults and feature gates for tf-aws-ecs
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  name = "test-ecs"
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module {
  source = "../../"
}

# ---------------------------------------------------------------------------
# Cluster-only mode: no task definitions or services by default
# ---------------------------------------------------------------------------
run "cluster_only_by_default" {
  command = plan

  assert {
    condition     = length(var.task_definitions) == 0
    error_message = "task_definitions must be empty by default (cluster-only mode)."
  }

  assert {
    condition     = length(var.services) == 0
    error_message = "services must be empty by default (cluster-only mode)."
  }
}

# ---------------------------------------------------------------------------
# Fargate is the default capacity provider
# ---------------------------------------------------------------------------
run "fargate_enabled_by_default" {
  command = plan

  assert {
    condition     = var.use_fargate == true
    error_message = "use_fargate must default to true."
  }
}

# ---------------------------------------------------------------------------
# EC2 capacity provider is disabled by default
# ---------------------------------------------------------------------------
run "ec2_capacity_disabled_by_default" {
  command = plan

  assert {
    condition     = var.use_ec2 == false
    error_message = "use_ec2 capacity provider must default to false."
  }
}

# ---------------------------------------------------------------------------
# Fargate Spot is disabled by default
# ---------------------------------------------------------------------------
run "fargate_spot_disabled_by_default" {
  command = plan

  assert {
    condition     = var.use_fargate_spot == false
    error_message = "use_fargate_spot must default to false."
  }
}

# ---------------------------------------------------------------------------
# Container Insights enabled by default
# ---------------------------------------------------------------------------
run "container_insights_default" {
  command = plan

  assert {
    condition     = var.container_insights == true
    error_message = "container_insights must be enabled by default."
  }
}

# ---------------------------------------------------------------------------
# enable_execute_command defaults to false inside service definitions
# ---------------------------------------------------------------------------
run "execute_command_default_false" {
  command = plan

  variables {
    name = "test-ecs-svc"
    services = {
      web = {
        task_definition_key = "app"
        network_configuration = {
          subnets = ["subnet-00000000000000000"]
        }
      }
    }
  }

  assert {
    condition     = var.services["web"].enable_execute_command == false
    error_message = "enable_execute_command must default to false inside service definitions."
  }
}

# ---------------------------------------------------------------------------
# BYO execution role: providing execution_role_arn in task def is accepted
# ---------------------------------------------------------------------------
run "byo_task_execution_role_accepted" {
  command = plan

  variables {
    name = "test-ecs-byo"
    task_definitions = {
      app = {
        cpu                   = 256
        memory                = 512
        execution_role_arn    = "arn:aws:iam::123456789012:role/test-role"
        container_definitions = jsonencode([{
          name  = "app"
          image = "nginx:latest"
        }])
      }
    }
  }

  assert {
    condition     = var.task_definitions["app"].execution_role_arn == "arn:aws:iam::123456789012:role/test-role"
    error_message = "BYO execution_role_arn must be accepted and passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# KMS key ARN defaults to null (encryption optional)
# ---------------------------------------------------------------------------
run "kms_key_arn_null_by_default" {
  command = plan

  assert {
    condition     = var.kms_key_arn == null
    error_message = "kms_key_arn must default to null."
  }
}
