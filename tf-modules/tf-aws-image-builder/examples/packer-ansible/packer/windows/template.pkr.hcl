packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
  }
}

variable "aws_region"    { type = string; default = "us-east-1" }
variable "environment"   { type = string; default = "dev" }
variable "instance_type" { type = string; default = "t3.large" }
variable "subnet_id"     { type = string; default = "" }
variable "s3_bucket"     { type = string }
variable "kms_key_id"    { type = string; default = "" }
variable "ami_name_prefix" { type = string; default = "golden-windows" }

data "amazon-ami" "base" {
  region = var.aws_region
  filters = {
    name                = "Windows_Server-2022-English-Full-Base-*"
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

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 100
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = var.kms_key_id
    delete_on_termination = true
  }

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "15m"

  user_data_file = "${path.module}/winrm_bootstrap.ps1"

  tags = {
    Name        = "${var.ami_name_prefix}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "packer"
    BuildDate   = "{{timestamp}}"
  }
}

build {
  sources = ["source.amazon-ebs.this"]

  # Download Ansible playbooks from S3 and run via PowerShell
  provisioner "powershell" {
    inline = [
      "pip install ansible pywinrm",
      "aws s3 sync s3://${var.s3_bucket}/ansible/ C:\\ansible\\ --region ${var.aws_region}",
      "if (Test-Path C:\\ansible\\requirements.yml) { ansible-galaxy install -r C:\\ansible\\requirements.yml }",
      "ansible-playbook C:\\ansible\\playbooks\\site.yml -c local -i 'localhost,' -e 'ansible_connection=local' -v"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
