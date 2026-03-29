#!/bin/bash
set -euo pipefail

TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
IP_LAST_OCTET=$(echo "$PRIVATE_IP" | awk -F. '{print $4}')

# Tag this instance with its actual hostname via AWS CLI (requires ec2:CreateTags on instance role)
REGION=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)
NEW_HOSTNAME="${hostname_prefix}${hostname_separator}${region_code}${hostname_separator}$${IP_LAST_OCTET}"

hostnamectl set-hostname "$NEW_HOSTNAME"

for attempt in 1 2 3 4 5; do
  if aws ec2 create-tags --region "$REGION" \
    --resources "$INSTANCE_ID" \
    --tags Key=Name,Value="$NEW_HOSTNAME" Key=Hostname,Value="$NEW_HOSTNAME"; then
    break
  fi

  if [ "$attempt" -eq 5 ]; then
    echo "Failed to update EC2 Name tag to $NEW_HOSTNAME after $attempt attempts" >&2
  else
    sleep 10
  fi
done

# Ensure SSM agent is running
systemctl enable amazon-ssm-agent || true
systemctl start  amazon-ssm-agent || true

%{ if bootstrap_enabled }
BOOTSTRAP_STATE_DIR="/var/lib/tf-aws-asg-bootstrap"
mkdir -p "$BOOTSTRAP_STATE_DIR"

cat > "$BOOTSTRAP_STATE_DIR/context.json" <<'EOF'
${bootstrap_context_json}
EOF

export TF_ASG_BOOTSTRAP_CONTEXT_FILE="$BOOTSTRAP_STATE_DIR/context.json"
export TF_ASG_BOOTSTRAP_HOSTNAME="$NEW_HOSTNAME"

%{ if bootstrap_s3_bucket != "" && bootstrap_s3_key_prefix != "" }
mkdir -p "$(dirname "${bootstrap_entrypoint}")"
aws s3 sync "s3://${bootstrap_s3_bucket}/${bootstrap_s3_key_prefix}/" "$(dirname "${bootstrap_entrypoint}")/" --region "$REGION"
%{ endif }
%{ if bootstrap_s3_bucket != "" && bootstrap_manifest_key != "" }
aws s3 cp "s3://${bootstrap_s3_bucket}/${bootstrap_manifest_key}" "$BOOTSTRAP_STATE_DIR/manifest.json" --region "$REGION"
export TF_ASG_BOOTSTRAP_MANIFEST_FILE="$BOOTSTRAP_STATE_DIR/manifest.json"
%{ endif }

if [ ! -f "${bootstrap_entrypoint}" ]; then
  echo "Bootstrap entrypoint not found at ${bootstrap_entrypoint}" >&2
  exit 1
fi

chmod +x "${bootstrap_entrypoint}" || true
"${bootstrap_entrypoint}"
%{ endif }

# Extra user-provided commands
${extra_commands}
