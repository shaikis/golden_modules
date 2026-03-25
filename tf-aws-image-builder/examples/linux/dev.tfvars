# dev / staging / qa — same subnet, different env tag
aws_region  = "us-east-1"
name        = "app-linux-golden"
environment = "dev"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

recipe_version     = "1.0.0"
root_volume_size   = 30
instance_types     = ["t3.medium"]
subnet_id          = "subnet-0dev-private" # shared lower-env subnet
security_group_ids = ["sg-0imagebuilder"]

# Weekly rebuild on Sundays at 2am (dev doesn't need daily)
pipeline_schedule_expression = "cron(0 2 ? * SUN *)"
pipeline_enabled             = true
distribution_regions         = []

# Custom hardening component (AWSTOE YAML inline)
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
  { component_arn = "arn:aws:imagebuilder:us-east-1:aws:component/aws-cli-version-2-linux/x.x.x" }
]
