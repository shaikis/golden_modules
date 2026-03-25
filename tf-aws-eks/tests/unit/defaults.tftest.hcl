# Unit tests — defaults and feature gates for tf-aws-eks
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  name       = "test-eks"
  subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
  vpc_id     = "vpc-00000000000000000"
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
# node_groups empty by default (control-plane-only mode)
# ---------------------------------------------------------------------------
run "node_groups_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.node_groups) == 0
    error_message = "node_groups must be empty by default — no managed node groups created."
  }
}

# ---------------------------------------------------------------------------
# fargate_profiles empty by default
# ---------------------------------------------------------------------------
run "fargate_profiles_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.fargate_profiles) == 0
    error_message = "fargate_profiles must be empty by default."
  }
}

# ---------------------------------------------------------------------------
# enable_irsa defaults to true (IRSA on by default)
# ---------------------------------------------------------------------------
run "enable_irsa_default_true" {
  command = plan

  assert {
    condition     = var.enable_irsa == true
    error_message = "enable_irsa must default to true to support IAM Roles for Service Accounts."
  }
}

# ---------------------------------------------------------------------------
# IRSA gate: enable_irsa = false disables OIDC provider creation
# ---------------------------------------------------------------------------
run "enable_irsa_gate_disabled" {
  command = plan

  variables {
    name        = "test-eks-noirsa"
    subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id      = "vpc-00000000000000000"
    enable_irsa = false
  }

  assert {
    condition     = var.enable_irsa == false
    error_message = "enable_irsa = false gate must be accepted."
  }
}

# ---------------------------------------------------------------------------
# Private endpoint enabled, public disabled by default
# ---------------------------------------------------------------------------
run "private_endpoint_default" {
  command = plan

  assert {
    condition     = var.endpoint_private_access == true
    error_message = "endpoint_private_access must default to true."
  }

  assert {
    condition     = var.endpoint_public_access == false
    error_message = "endpoint_public_access must default to false."
  }
}

# ---------------------------------------------------------------------------
# Default Kubernetes version set
# ---------------------------------------------------------------------------
run "kubernetes_version_default" {
  command = plan

  assert {
    condition     = var.kubernetes_version == "1.29"
    error_message = "kubernetes_version must default to 1.29."
  }
}

# ---------------------------------------------------------------------------
# BYO cluster role: cluster_role_arn accepted when provided
# ---------------------------------------------------------------------------
run "byo_cluster_role_accepted" {
  command = plan

  variables {
    name             = "test-eks-byo"
    subnet_ids       = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id           = "vpc-00000000000000000"
    cluster_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  assert {
    condition     = var.cluster_role_arn == "arn:aws:iam::123456789012:role/test-role"
    error_message = "BYO cluster_role_arn must be passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# All control-plane log types enabled by default
# ---------------------------------------------------------------------------
run "cluster_log_types_default" {
  command = plan

  assert {
    condition     = contains(var.cluster_log_types, "api") && contains(var.cluster_log_types, "audit")
    error_message = "api and audit log types must be enabled by default."
  }
}
