# staging — dedicated subnets
aws_region  = "us-east-1"
name        = "app-windows-golden"
environment = "staging"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

recipe_version     = "1.0.0"
root_volume_size   = 100
instance_types     = ["t3.large"]
subnet_id          = "subnet-0stg-private"
security_group_ids = ["sg-0imagebuilder-stg"]

pipeline_schedule_expression = "cron(0 3 ? * SUN *)"
pipeline_enabled             = true
distribution_regions         = []

custom_components = {
  win_hardening = {
    platform    = "Windows"
    version     = "1.0.0"
    description = "Windows Server hardening - CIS Level 1"
    data        = <<-YAML
      name: WindowsHardening
      description: CIS Windows Server 2022 L1 baseline
      schemaVersion: 1.0
      phases:
        - name: build
          steps:
            - name: DisableGuestAccount
              action: ExecutePowerShell
              inputs:
                commands:
                  - Disable-LocalUser -Name "Guest"
    YAML
  }
}

components = [
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/amazon-cloudwatch-agent-windows/x.x.x" },
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/aws-cli-version-2-windows/x.x.x" }
]
