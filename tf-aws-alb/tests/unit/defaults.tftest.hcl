# Unit tests — verify default variable values for tf-aws-alb
# command = plan; no real AWS resources are created.

run "alb_defaults" {
  command = plan

  variables {
    name    = "test-alb"
    vpc_id  = "vpc-00000000000000001"
    subnets = ["subnet-00000000000000001", "subnet-00000000000000002"]
  }

  # internal defaults to false (internet-facing)
  assert {
    condition     = var.internal == false
    error_message = "Expected internal to default to false."
  }

  # load_balancer_type defaults to application
  assert {
    condition     = var.load_balancer_type == "application"
    error_message = "Expected load_balancer_type to default to 'application'."
  }

  # access logs disabled by default
  assert {
    condition     = var.access_logs_enabled == false
    error_message = "Expected access_logs_enabled to default to false."
  }

  # deletion protection enabled by default
  assert {
    condition     = var.enable_deletion_protection == true
    error_message = "Expected enable_deletion_protection to default to true."
  }

  # HTTP/2 enabled by default
  assert {
    condition     = var.enable_http2 == true
    error_message = "Expected enable_http2 to default to true."
  }

  # idle timeout defaults to 60 seconds
  assert {
    condition     = var.idle_timeout == 60
    error_message = "Expected idle_timeout to default to 60."
  }

  # no target groups by default
  assert {
    condition     = length(var.target_groups) == 0
    error_message = "Expected target_groups to default to empty map."
  }

  # no listeners by default
  assert {
    condition     = length(var.listeners) == 0
    error_message = "Expected listeners to default to empty map."
  }
}
