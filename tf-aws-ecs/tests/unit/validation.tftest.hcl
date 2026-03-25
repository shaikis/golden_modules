# Unit tests — variable validation rules for tf-aws-ecs
# command = plan  →  no AWS resources are created; free to run on every PR.

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
# Minimal cluster-only: just name is required
# ---------------------------------------------------------------------------
run "cluster_only_minimal_valid" {
  command = plan

  variables {
    name = "test-ecs-minimal"
  }

  assert {
    condition     = var.name == "test-ecs-minimal"
    error_message = "Cluster-only module must accept just a name."
  }
}

# ---------------------------------------------------------------------------
# Task definition: valid awsvpc network mode accepted
# ---------------------------------------------------------------------------
run "task_def_network_mode_awsvpc_accepted" {
  command = plan

  variables {
    name = "test-ecs-td"
    task_definitions = {
      app = {
        cpu                   = 256
        memory                = 512
        network_mode          = "awsvpc"
        container_definitions = jsonencode([{
          name  = "app"
          image = "nginx:latest"
        }])
      }
    }
  }

  assert {
    condition     = var.task_definitions["app"].network_mode == "awsvpc"
    error_message = "network_mode awsvpc must be accepted."
  }
}

# ---------------------------------------------------------------------------
# Task definition: Fargate requires_compatibilities accepted
# ---------------------------------------------------------------------------
run "task_def_fargate_compat_accepted" {
  command = plan

  variables {
    name = "test-ecs-fargate"
    task_definitions = {
      app = {
        cpu                      = 512
        memory                   = 1024
        requires_compatibilities = ["FARGATE"]
        container_definitions    = jsonencode([{
          name  = "app"
          image = "nginx:latest"
        }])
      }
    }
  }

  assert {
    condition     = contains(var.task_definitions["app"].requires_compatibilities, "FARGATE")
    error_message = "FARGATE compatibility must be accepted."
  }
}

# ---------------------------------------------------------------------------
# Service: desired_count = 0 accepted (scale-to-zero pattern)
# ---------------------------------------------------------------------------
run "service_desired_count_zero_accepted" {
  command = plan

  variables {
    name = "test-ecs-zero"
    services = {
      web = {
        task_definition_key   = "app"
        desired_count         = 0
        network_configuration = {
          subnets = ["subnet-00000000000000000"]
        }
      }
    }
  }

  assert {
    condition     = var.services["web"].desired_count == 0
    error_message = "desired_count = 0 must be accepted for scale-to-zero."
  }
}

# ---------------------------------------------------------------------------
# Service: deployment circuit breaker enabled by default
# ---------------------------------------------------------------------------
run "deployment_circuit_breaker_default" {
  command = plan

  variables {
    name = "test-ecs-cb"
    services = {
      web = {
        task_definition_key   = "app"
        network_configuration = {
          subnets = ["subnet-00000000000000000"]
        }
      }
    }
  }

  assert {
    condition     = var.services["web"].deployment_circuit_breaker.enable == true
    error_message = "deployment_circuit_breaker must default to enabled."
  }
}

# ---------------------------------------------------------------------------
# Capacity provider strategy: valid strategy accepted
# ---------------------------------------------------------------------------
run "capacity_provider_strategy_accepted" {
  command = plan

  variables {
    name = "test-ecs-cps"
    services = {
      web = {
        task_definition_key   = "app"
        network_configuration = {
          subnets = ["subnet-00000000000000000"]
        }
        capacity_provider_strategy = [
          {
            capacity_provider = "FARGATE"
            weight            = 1
          }
        ]
      }
    }
  }

  assert {
    condition     = length(var.services["web"].capacity_provider_strategy) == 1
    error_message = "capacity_provider_strategy must accept a valid strategy list."
  }
}
