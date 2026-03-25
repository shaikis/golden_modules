# Integration tests — tf-aws-ecs
# Cost estimate: $0.00 — ECS clusters have no charge; tasks (Fargate) are billed per vCPU/memory.
# This test creates a cluster ONLY (no task definitions or services) to avoid compute costs.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create an ECS cluster and verify outputs ─────────────────────────
# SKIP_IN_CI
run "create_ecs_cluster" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name               = "tftest-ecs-cluster"
    environment        = "test"
    container_insights = false
    use_fargate        = true
    use_fargate_spot   = false
    use_ec2            = false
    task_definitions   = {}
    services           = {}
  }

  assert {
    condition     = length(output.cluster_arn) > 0
    error_message = "cluster_arn must be non-empty."
  }

  assert {
    condition     = length(output.cluster_name) > 0
    error_message = "cluster_name must be non-empty."
  }

  assert {
    condition     = length(output.cluster_id) > 0
    error_message = "cluster_id must be non-empty."
  }

  assert {
    condition     = startswith(output.cluster_arn, "arn:aws:ecs:")
    error_message = "cluster_arn must start with 'arn:aws:ecs:'."
  }
}

# ── Test 2: Cluster with Container Insights enabled ──────────────────────────
# SKIP_IN_CI
run "create_ecs_cluster_with_insights" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name               = "tftest-ecs-insights"
    environment        = "test"
    container_insights = true
    use_fargate        = true
    task_definitions   = {}
    services           = {}
  }

  assert {
    condition     = length(output.cluster_arn) > 0
    error_message = "cluster_arn must be non-empty."
  }

  assert {
    condition     = var.container_insights == true
    error_message = "container_insights must be true."
  }
}
