# Unit tests — variable validation rules for tf-aws-image-builder
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
# platform: "Linux" accepted
# ---------------------------------------------------------------------------
run "platform_linux_accepted" {
  command = plan

  variables {
    name     = "test-ib-linux"
    platform = "Linux"
  }

  assert {
    condition     = var.platform == "Linux"
    error_message = "platform 'Linux' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# platform: "Windows" accepted
# ---------------------------------------------------------------------------
run "platform_windows_accepted" {
  command = plan

  variables {
    name     = "test-ib-windows"
    platform = "Windows"
  }

  assert {
    condition     = var.platform == "Windows"
    error_message = "platform 'Windows' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# root_volume_type: "gp3" default accepted
# ---------------------------------------------------------------------------
run "root_volume_type_gp3_accepted" {
  command = plan

  variables {
    name             = "test-ib-vol"
    root_volume_type = "gp3"
  }

  assert {
    condition     = var.root_volume_type == "gp3"
    error_message = "root_volume_type 'gp3' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# root_volume_size: default 30 accepted
# ---------------------------------------------------------------------------
run "root_volume_size_default_accepted" {
  command = plan

  variables {
    name = "test-ib-volsize"
  }

  assert {
    condition     = var.root_volume_size == 30
    error_message = "root_volume_size must default to 30."
  }
}

# ---------------------------------------------------------------------------
# components: empty list accepted
# ---------------------------------------------------------------------------
run "components_empty_list_accepted" {
  command = plan

  variables {
    name       = "test-ib-nocomp"
    components = []
  }

  assert {
    condition     = length(var.components) == 0
    error_message = "components must accept an empty list."
  }
}

# ---------------------------------------------------------------------------
# components: valid component ARN list accepted
# ---------------------------------------------------------------------------
run "components_with_arn_accepted" {
  command = plan

  variables {
    name = "test-ib-comp"
    components = [
      {
        component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/amazon-cloudwatch-agent-linux/x.x.x"
      }
    ]
  }

  assert {
    condition     = length(var.components) == 1
    error_message = "components must accept a list with a valid ARN."
  }
}

# ---------------------------------------------------------------------------
# instance_types: default ["t3.medium"] accepted
# ---------------------------------------------------------------------------
run "instance_types_default_accepted" {
  command = plan

  variables {
    name = "test-ib-types"
  }

  assert {
    condition     = contains(var.instance_types, "t3.medium")
    error_message = "instance_types must default to include t3.medium."
  }
}

# ---------------------------------------------------------------------------
# ami_launch_permissions: list of account IDs accepted
# ---------------------------------------------------------------------------
run "ami_launch_permissions_accepted" {
  command = plan

  variables {
    name                   = "test-ib-perms"
    ami_launch_permissions = ["123456789012", "987654321098"]
  }

  assert {
    condition     = length(var.ami_launch_permissions) == 2
    error_message = "ami_launch_permissions must accept a list of AWS account IDs."
  }
}

# ---------------------------------------------------------------------------
# pipeline_enabled: false accepted (pause pipeline)
# ---------------------------------------------------------------------------
run "pipeline_disabled_accepted" {
  command = plan

  variables {
    name             = "test-ib-paused"
    pipeline_enabled = false
  }

  assert {
    condition     = var.pipeline_enabled == false
    error_message = "pipeline_enabled = false must be accepted to pause the pipeline."
  }
}

# ---------------------------------------------------------------------------
# custom_components: map of inline components accepted
# ---------------------------------------------------------------------------
run "custom_components_accepted" {
  command = plan

  variables {
    name = "test-ib-custom"
    custom_components = {
      harden = {
        data = <<-YAML
          name: Harden
          description: Hardening steps
          schemaVersion: 1.0
          phases:
            - name: build
              steps:
                - name: Disable-Root
                  action: ExecuteBash
                  inputs:
                    commands:
                      - passwd -l root
        YAML
      }
    }
  }

  assert {
    condition     = contains(keys(var.custom_components), "harden")
    error_message = "custom_components map must be accepted."
  }
}
