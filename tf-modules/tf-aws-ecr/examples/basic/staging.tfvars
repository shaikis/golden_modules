# staging — same registry, environment label changes
aws_region  = "us-east-1"
name        = "platform"
environment = "staging"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

repositories = {
  api      = { scan_on_push = true }
  frontend = { scan_on_push = true }
  worker   = { scan_on_push = true }
}

push_principal_arns = [
  "arn:aws:iam::111122223333:role/github-actions-ci"
]
cross_account_ids = []
