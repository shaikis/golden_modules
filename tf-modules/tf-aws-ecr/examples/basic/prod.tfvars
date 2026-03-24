aws_region  = "us-east-1"
name        = "platform"
environment = "prod"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

repositories = {
  api      = { scan_on_push = true; image_tag_mutability = "IMMUTABLE" }
  frontend = { scan_on_push = true; image_tag_mutability = "IMMUTABLE" }
  worker   = { scan_on_push = true; image_tag_mutability = "IMMUTABLE" }
}

push_principal_arns = [
  "arn:aws:iam::111122223333:role/github-actions-ci"
]

# Grant EKS worker nodes in prod account pull access
cross_account_ids = ["444455556666"]
