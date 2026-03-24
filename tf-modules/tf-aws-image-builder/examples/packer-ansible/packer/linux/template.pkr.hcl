# Packer template — used standalone (outside Image Builder) or referenced for context
# Usage: packer build -var-file=../../dev.pkrvars.hcl template.pkr.hcl

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.0"
    }
  }
}

variable "aws_region"   { type = string; default = "us-east-1" }
variable "environment"  { type = string; default = "dev" }
variable "instance_type"{ type = string; default = "t3.medium" }
variable "subnet_id"    { type = string; default = "" }
variable "s3_bucket"    { type = string }
variable "kms_key_id"   { type = string; default = "" }
variable "ami_name_prefix" { type = string; default = "golden-linux" }

data "amazon-ami" "base" {
  region = var.aws_region
  filters = {
    name                = "al2023-ami-*-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
}

source "amazon-ebs" "this" {
  region        = var.aws_region
  instance_type = var.instance_type
  source_ami    = data.amazon-ami.base.id
  subnet_id     = var.subnet_id

  ami_name    = "${var.ami_name_prefix}-${var.environment}-{{timestamp}}"
  ami_regions = [var.aws_region]

  # IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = var.kms_key_id
    delete_on_termination = true
  }

  communicator  = "ssh"
  ssh_username  = "ec2-user"
  ssh_timeout   = "10m"

  tags = {
    Name        = "${var.ami_name_prefix}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "packer"
    BuildDate   = "{{timestamp}}"
  }
}

build {
  sources = ["source.amazon-ebs.this"]

  # Download Ansible playbooks from S3
  provisioner "shell" {
    inline = [
      "sudo dnf install -y ansible-core",
      "aws s3 sync s3://${var.s3_bucket}/ansible/ /opt/ansible/ --region ${var.aws_region}",
      "ansible-galaxy install -r /opt/ansible/requirements.yml || true"
    ]
  }

  # Run Ansible playbook
  provisioner "ansible-local" {
    playbook_file = "/opt/ansible/playbooks/site.yml"
    command       = "ANSIBLE_FORCE_COLOR=1 ansible-playbook"
    extra_arguments = ["-c", "local", "-i", "localhost,", "-v"]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
