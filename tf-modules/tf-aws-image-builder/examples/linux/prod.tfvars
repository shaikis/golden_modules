aws_region  = "us-east-1"
name        = "app-linux-golden"
environment = "prod"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

recipe_version     = "1.0.0"
root_volume_size   = 50
instance_types     = ["t3.large"]
subnet_id          = "subnet-0prod-private" # dedicated prod subnet
security_group_ids = ["sg-0imagebuilder-prod"]

# Daily rebuild at 2am for prod golden image
pipeline_schedule_expression = "cron(0 2 * * ? *)"
pipeline_enabled             = true
distribution_regions         = ["us-west-2", "eu-west-1"] # DR regions

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
            - name: EnableAuditd
              action: ExecuteBash
              inputs:
                commands:
                  - yum install -y audit auditd
                  - systemctl enable auditd
    YAML
  }
}

components = [
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/amazon-cloudwatch-agent-linux/x.x.x" },
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/aws-cli-version-2-linux/x.x.x" },
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/inspector-test-linux/x.x.x" }
]
