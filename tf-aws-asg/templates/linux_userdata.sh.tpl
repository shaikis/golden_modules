#!/bin/bash
set -e

# Generate a unique 8-char suffix from instance-id
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
SHORT_ID=$(echo "$INSTANCE_ID" | tr -d 'i-' | cut -c1-8)
NEW_HOSTNAME="${hostname_prefix}-$SHORT_ID"

hostnamectl set-hostname "$NEW_HOSTNAME"

# Tag this instance with its actual hostname via AWS CLI (requires ec2:CreateTags on instance role)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws ec2 create-tags --region "$REGION" \
  --resources "$INSTANCE_ID" \
  --tags Key=Name,Value="$NEW_HOSTNAME" Key=Hostname,Value="$NEW_HOSTNAME" || true

# Ensure SSM agent is running
systemctl enable amazon-ssm-agent || true
systemctl start  amazon-ssm-agent || true

# Extra user-provided commands
${extra_commands}
