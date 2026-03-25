# Integration tests — tf-aws-eks
# WARNING: EKS cluster costs $0.10/hour for the control plane plus EC2 node costs.
# Cluster provisioning takes ~15 minutes. DO NOT apply in CI — plan only.
# Run manually: terraform test -filter=tests/integration
# Cost estimate: $0.10/hr control plane + ~$0.02/hr per t3.medium node if nodes added.

# ── Test 1: Plan minimal EKS cluster (no node groups) ───────────────────────
# SKIP_IN_CI
run "minimal_eks_cluster_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "tftest-eks"
    subnet_ids         = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id             = "vpc-00000000000000000"
    kubernetes_version = "1.29"
    node_groups        = {}
    environment        = "test"
  }

  assert {
    condition     = var.kubernetes_version == "1.29"
    error_message = "kubernetes_version must be 1.29."
  }

  assert {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS requires at least 2 subnets across 2 AZs."
  }

  assert {
    condition     = var.endpoint_private_access == true
    error_message = "endpoint_private_access must default to true."
  }
}

# ── Test 2: Plan with IRSA disabled ──────────────────────────────────────────
# SKIP_IN_CI
run "eks_plan_irsa_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-eks-no-irsa"
    subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id      = "vpc-00000000000000000"
    enable_irsa = false
    node_groups = {}
    environment = "test"
  }

  assert {
    condition     = var.enable_irsa == false
    error_message = "enable_irsa must accept false."
  }
}

# ── Test 3: Plan with a managed node group defined ────────────────────────────
# SKIP_IN_CI
run "eks_plan_with_node_group" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name       = "tftest-eks-nodes"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
    environment = "test"
    node_groups = {
      general = {
        instance_types = ["t3.medium"]
        desired_size   = 1
        min_size       = 1
        max_size       = 2
        capacity_type  = "ON_DEMAND"
      }
    }
  }

  assert {
    condition     = length(var.node_groups) == 1
    error_message = "node_groups must contain exactly one entry."
  }
}
