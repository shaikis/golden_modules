# Integration test — tf-aws-ebs basic
# command = apply (creates real AWS resources — costs money)
# Prerequisites: AWS credentials with EC2 EBS permissions

provider "aws" {
  region = "us-east-1"
}

variables {
  name = "tftest-ebs"
  volumes = {
    test_data = {
      availability_zone = "us-east-1a"
      size              = 20
      type              = "gp3"
      final_snapshot    = false
    }
  }
}

# SKIP_IN_CI
run "basic_ebs_volume" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = length(output.volume_ids) > 0
    error_message = "At least one volume ID should be present after apply."
  }

  assert {
    condition     = length(output.volume_arns) > 0
    error_message = "At least one volume ARN should be present after apply."
  }
}
