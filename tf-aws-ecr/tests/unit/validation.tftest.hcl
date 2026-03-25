# Unit tests — variable validation rules for tf-aws-ecr
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
# image_tag_mutability: "IMMUTABLE" accepted
# ---------------------------------------------------------------------------
run "image_tag_immutable_accepted" {
  command = plan

  variables {
    name = "test-ecr-immutable"
    repositories = {
      app = {
        image_tag_mutability = "IMMUTABLE"
      }
    }
  }

  assert {
    condition     = var.repositories["app"].image_tag_mutability == "IMMUTABLE"
    error_message = "image_tag_mutability IMMUTABLE must be accepted."
  }
}

# ---------------------------------------------------------------------------
# image_tag_mutability: "MUTABLE" accepted
# ---------------------------------------------------------------------------
run "image_tag_mutable_accepted" {
  command = plan

  variables {
    name = "test-ecr-mutable"
    repositories = {
      app = {
        image_tag_mutability = "MUTABLE"
      }
    }
  }

  assert {
    condition     = var.repositories["app"].image_tag_mutability == "MUTABLE"
    error_message = "image_tag_mutability MUTABLE must be accepted."
  }
}

# ---------------------------------------------------------------------------
# encryption_type: "KMS" default accepted
# ---------------------------------------------------------------------------
run "encryption_type_kms_accepted" {
  command = plan

  variables {
    name = "test-ecr-kms"
    repositories = {
      app = {
        encryption_type = "KMS"
      }
    }
  }

  assert {
    condition     = var.repositories["app"].encryption_type == "KMS"
    error_message = "encryption_type KMS must be accepted."
  }
}

# ---------------------------------------------------------------------------
# encryption_type: "AES256" accepted
# ---------------------------------------------------------------------------
run "encryption_type_aes256_accepted" {
  command = plan

  variables {
    name = "test-ecr-aes"
    repositories = {
      app = {
        encryption_type = "AES256"
      }
    }
  }

  assert {
    condition     = var.repositories["app"].encryption_type == "AES256"
    error_message = "encryption_type AES256 must be accepted."
  }
}

# ---------------------------------------------------------------------------
# force_delete: false (default) accepted
# ---------------------------------------------------------------------------
run "force_delete_false_accepted" {
  command = plan

  variables {
    name = "test-ecr-nodelete"
    repositories = {
      app = {
        force_delete = false
      }
    }
  }

  assert {
    condition     = var.repositories["app"].force_delete == false
    error_message = "force_delete = false must be accepted."
  }
}

# ---------------------------------------------------------------------------
# Multiple repositories accepted
# ---------------------------------------------------------------------------
run "multiple_repositories_accepted" {
  command = plan

  variables {
    name = "test-ecr-multi"
    repositories = {
      frontend = {}
      backend  = {}
      worker   = {}
    }
  }

  assert {
    condition     = length(var.repositories) == 3
    error_message = "Multiple repository definitions must be accepted."
  }
}

# ---------------------------------------------------------------------------
# lifecycle_tag_prefixes: custom prefixes accepted
# ---------------------------------------------------------------------------
run "lifecycle_tag_prefixes_custom_accepted" {
  command = plan

  variables {
    name                   = "test-ecr-lc"
    lifecycle_tag_prefixes = ["prod", "staging", "v"]
  }

  assert {
    condition     = length(var.lifecycle_tag_prefixes) == 3
    error_message = "Custom lifecycle_tag_prefixes must be accepted."
  }
}

# ---------------------------------------------------------------------------
# push_principal_arns: CI/CD role ARN accepted
# ---------------------------------------------------------------------------
run "push_principal_arns_accepted" {
  command = plan

  variables {
    name                = "test-ecr-push"
    push_principal_arns = ["arn:aws:iam::123456789012:role/test-role"]
  }

  assert {
    condition     = length(var.push_principal_arns) == 1
    error_message = "push_principal_arns must accept a list of IAM role ARNs."
  }
}
