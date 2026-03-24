# staging — dedicated subnets, more frequent builds
aws_region  = "us-east-1"
name        = "app-linux-golden"
environment = "staging"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

recipe_version     = "1.0.0"
root_volume_size   = 30
instance_types     = ["t3.medium"]
subnet_id          = "subnet-0stg-private"
security_group_ids = ["sg-0imagebuilder-stg"]

pipeline_schedule_expression = "cron(0 3 ? * SUN *)"
pipeline_enabled             = true
distribution_regions         = []

custom_components = {
  hardening = {
    version     = "1.0.0"
    description = "CIS hardening baseline for Amazon Linux 2023"
    data        = <<-YAML
      name: CIS Hardening
      description: Apply CIS Level 1 baseline
      schemaVersion: 1.0
      phases:
        - name: build
          steps:
            - name: DisableRootLogin
              action: ExecuteBash
              inputs:
                commands:
                  - sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    YAML
  }
}

components = [
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/amazon-cloudwatch-agent-linux/x.x.x" },
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/aws-cli-version-2-linux/x.x.x" }
]
