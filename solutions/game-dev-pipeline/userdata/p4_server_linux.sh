#!/bin/bash
set -e

# =============================================================================
# Perforce P4D Installation Script — Amazon Linux 2023
# Runs on first boot of the P4 Commit Server EC2 instance.
#
# What this script does:
#   1. Adds the Perforce YUM repository
#   2. Installs helix-p4d (P4D server daemon)
#   3. Waits for the EBS data volume (/dev/xvdf) to attach, then formats and
#      mounts it at /data
#   4. Configures P4D to store depot files on /data/p4/depot
#   5. Starts the p4d systemd service and performs initial setup
#
# After deployment:
#   - Connect: p4 -p ssl:p4.<your-domain>:1666 -u admin info
#   - Change admin password immediately (stored in Secrets Manager)
#   - Configure SSL: p4d -Gc (generate server certificate)
# =============================================================================

P4D_VERSION="r23.2"
P4D_PORT=1666
P4D_ROOT="/data/p4/depot"
P4D_LOG="/var/log/p4d.log"
DATA_DEVICE="/dev/xvdf"
DATA_MOUNT="/data"

echo "==> [$(date)] Starting P4D installation on Amazon Linux 2023"

# ---------------------------------------------------------------------------
# 1. Add Perforce package repository
# ---------------------------------------------------------------------------
echo "==> Adding Perforce YUM repository"
rpm --import https://package.perforce.com/perforce.pubkey

cat > /etc/yum.repos.d/perforce.repo << 'REPO'
[perforce]
name=Perforce
baseurl=https://package.perforce.com/yum/rhel/8/x86_64/
enabled=1
gpgcheck=1
REPO

# ---------------------------------------------------------------------------
# 2. Install P4D
# ---------------------------------------------------------------------------
echo "==> Installing helix-p4d"
dnf install -y helix-p4d

# ---------------------------------------------------------------------------
# 3. Wait for EBS data volume to attach, format, and mount
# ---------------------------------------------------------------------------
echo "==> Waiting for EBS data volume ${DATA_DEVICE}"
ATTEMPTS=0
MAX_ATTEMPTS=30
while [ ! -b "${DATA_DEVICE}" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  echo "  Waiting for ${DATA_DEVICE}... attempt $((ATTEMPTS + 1))/${MAX_ATTEMPTS}"
  sleep 10
  ATTEMPTS=$((ATTEMPTS + 1))
done

if [ ! -b "${DATA_DEVICE}" ]; then
  echo "ERROR: EBS volume ${DATA_DEVICE} did not appear after ${MAX_ATTEMPTS} attempts."
  echo "  Check that the tf-aws-ebs volume_attachments block is correctly configured."
  exit 1
fi

# Format only if the volume has no filesystem
FSTYPE=$(blkid -o value -s TYPE "${DATA_DEVICE}" 2>/dev/null || echo "")
if [ -z "${FSTYPE}" ]; then
  echo "==> Formatting ${DATA_DEVICE} as ext4"
  mkfs -t ext4 "${DATA_DEVICE}"
else
  echo "==> ${DATA_DEVICE} already formatted as ${FSTYPE} — skipping mkfs"
fi

# Mount the volume
mkdir -p "${DATA_MOUNT}"
mount "${DATA_DEVICE}" "${DATA_MOUNT}"

# Persist the mount across reboots
UUID=$(blkid -o value -s UUID "${DATA_DEVICE}")
if ! grep -q "${UUID}" /etc/fstab; then
  echo "UUID=${UUID} ${DATA_MOUNT} ext4 defaults,nofail 0 2" >> /etc/fstab
fi

# ---------------------------------------------------------------------------
# 4. Create P4D directory structure and set permissions
# ---------------------------------------------------------------------------
echo "==> Creating P4D directories under ${DATA_MOUNT}"
mkdir -p "${P4D_ROOT}"
mkdir -p /data/p4/logs
chown -R perforce:perforce /data/p4

# ---------------------------------------------------------------------------
# 5. Configure P4D
# ---------------------------------------------------------------------------
echo "==> Writing P4D configuration"
cat > /etc/perforce/p4dconfig << CONF
P4PORT=ssl:${P4D_PORT}
P4ROOT=${P4D_ROOT}
P4LOG=${P4D_LOG}
CONF

# Generate a self-signed SSL certificate for the server
# In production, replace with a CA-signed cert or use ACM Private CA
if [ ! -f /etc/perforce/ssl/privatekey.txt ]; then
  echo "==> Generating P4D SSL certificate"
  mkdir -p /etc/perforce/ssl
  chown perforce:perforce /etc/perforce/ssl
  sudo -u perforce p4d -Gc
fi

# ---------------------------------------------------------------------------
# 6. Start P4D service
# ---------------------------------------------------------------------------
echo "==> Enabling and starting p4d service"
systemctl enable p4d
systemctl start p4d

# Wait for P4D to initialize and be ready to accept connections
echo "==> Waiting for P4D to be ready"
ATTEMPTS=0
MAX_ATTEMPTS=12
while ! p4 -p "ssl:localhost:${P4D_PORT}" info > /dev/null 2>&1 && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  sleep 5
  ATTEMPTS=$((ATTEMPTS + 1))
done

# ---------------------------------------------------------------------------
# 7. Initial P4D setup — trust the server certificate and set admin password
# ---------------------------------------------------------------------------
echo "==> Performing initial P4D configuration"
export P4PORT="ssl:localhost:${P4D_PORT}"

# Trust the auto-generated server certificate
p4 -u admin trust -y || true

# Set initial admin password from Secrets Manager
# The Terraform module stores the initial password in Secrets Manager.
# Retrieve and apply it on first boot only.
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
SECRET_NAME=$(aws ssm get-parameter \
  --name "/game-dev/p4-admin-secret-arn" \
  --region "${REGION}" \
  --query "Parameter.Value" \
  --output text 2>/dev/null || echo "")

if [ -n "${SECRET_NAME}" ]; then
  ADMIN_PASS=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRET_NAME}" \
    --region "${REGION}" \
    --query "SecretString" \
    --output text | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
  echo "${ADMIN_PASS}" | p4 -u admin passwd || true
fi

# ---------------------------------------------------------------------------
# 8. Install and configure CloudWatch Agent for P4D monitoring
# ---------------------------------------------------------------------------
echo "==> Installing CloudWatch Agent"
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWA'
{
  "metrics": {
    "namespace": "GameDevPipeline/P4Server",
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_idle", "cpu_usage_user"], "metrics_collection_interval": 60 },
      "disk": { "measurement": ["used_percent"], "resources": ["/", "/data"], "metrics_collection_interval": 60 },
      "mem": { "measurement": ["mem_used_percent"], "metrics_collection_interval": 60 }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/p4d.log",
            "log_group_name": "/ec2/p4-server",
            "log_stream_name": "{instance_id}/p4d"
          }
        ]
      }
    }
  }
}
CWA

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "==> [$(date)] P4D installation complete."
echo "==> Server listening on ssl:$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):${P4D_PORT}"
echo "==> IMPORTANT: Change the admin password on first login."
echo "==> Connect with: p4 -p ssl:p4.<your-domain>:1666 -u admin info"
