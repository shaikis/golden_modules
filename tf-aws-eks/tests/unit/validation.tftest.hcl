# Unit tests — variable validation rules for tf-aws-eks
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
# ip_family: ipv4 accepted
# ---------------------------------------------------------------------------
run "ip_family_ipv4_accepted" {
  command = plan

  variables {
    name       = "test-eks-ipv4"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
    ip_family  = "ipv4"
  }

  assert {
    condition     = var.ip_family == "ipv4"
    error_message = "ip_family 'ipv4' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# ip_family: ipv6 accepted
# ---------------------------------------------------------------------------
run "ip_family_ipv6_accepted" {
  command = plan

  variables {
    name       = "test-eks-ipv6"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
    ip_family  = "ipv6"
  }

  assert {
    condition     = var.ip_family == "ipv6"
    error_message = "ip_family 'ipv6' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# cluster_log_retention_days: default 90 accepted
# ---------------------------------------------------------------------------
run "log_retention_days_default" {
  command = plan

  variables {
    name       = "test-eks-logs"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
  }

  assert {
    condition     = var.cluster_log_retention_days == 90
    error_message = "cluster_log_retention_days must default to 90."
  }
}

# ---------------------------------------------------------------------------
# service_ipv4_cidr: default CIDR accepted
# ---------------------------------------------------------------------------
run "service_ipv4_cidr_default" {
  command = plan

  variables {
    name       = "test-eks-cidr"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
  }

  assert {
    condition     = var.service_ipv4_cidr == "172.20.0.0/16"
    error_message = "service_ipv4_cidr must default to 172.20.0.0/16."
  }
}

# ---------------------------------------------------------------------------
# node_group: valid ON_DEMAND capacity type accepted
# ---------------------------------------------------------------------------
run "node_group_on_demand_accepted" {
  command = plan

  variables {
    name       = "test-eks-ng"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
    node_groups = {
      general = {
        capacity_type = "ON_DEMAND"
      }
    }
  }

  assert {
    condition     = var.node_groups["general"].capacity_type == "ON_DEMAND"
    error_message = "ON_DEMAND capacity type must be accepted for node groups."
  }
}

# ---------------------------------------------------------------------------
# node_group: SPOT capacity type accepted
# ---------------------------------------------------------------------------
run "node_group_spot_accepted" {
  command = plan

  variables {
    name       = "test-eks-spot"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
    node_groups = {
      spot = {
        capacity_type = "SPOT"
      }
    }
  }

  assert {
    condition     = var.node_groups["spot"].capacity_type == "SPOT"
    error_message = "SPOT capacity type must be accepted for node groups."
  }
}

# ---------------------------------------------------------------------------
# cluster_addons: default addons set correctly
# ---------------------------------------------------------------------------
run "default_addons_present" {
  command = plan

  variables {
    name       = "test-eks-addons"
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_id     = "vpc-00000000000000000"
  }

  assert {
    condition     = contains(keys(var.cluster_addons), "coredns")
    error_message = "coredns addon must be in the default cluster_addons map."
  }

  assert {
    condition     = contains(keys(var.cluster_addons), "vpc-cni")
    error_message = "vpc-cni addon must be in the default cluster_addons map."
  }
}
