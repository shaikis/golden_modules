# ===========================================================================
# Image Baker: Packer + Ansible stored in S3
#
# Flow:
#   1. Packer template (.pkr.hcl) + Ansible playbooks uploaded to S3
#   2. EC2 Image Builder "bootstrap" component downloads them from S3
#   3. Ansible runs inside Image Builder via ExecuteAnsiblePlaybook action
#      (for Windows: WinRM-based via ExecutePowerShell + ansible-playbook)
#   4. Packer is used as an ALTERNATIVE standalone approach (null_resource)
#      → uncomment the packer_build block at the bottom if preferred
# ===========================================================================
provider "aws" { region = var.aws_region }

# ── KMS ──────────────────────────────────────────────────────────────────
module "kms" {
  source      = "../../../tf-aws-kms"
  name_prefix = "${var.name}-images"
  tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  keys = {
    image_builder = {
      description = "KMS key for ${var.name} Image Builder artifacts"
    }
  }
}

# ── S3 bucket for Packer templates + Ansible playbooks ───────────────────
module "s3_artifacts" {
  source             = "../../../tf-aws-s3"
  bucket_name        = "${var.name}-image-artifacts-${var.environment}"
  environment        = var.environment
  project            = var.project
  kms_master_key_id  = module.kms.key_arns["image_builder"]
  versioning_enabled = true
}

# Upload packer template to S3
resource "aws_s3_object" "packer_template" {
  bucket = module.s3_artifacts.bucket_id
  key    = "packer/${var.platform == "Windows" ? "windows" : "linux"}/template.pkr.hcl"
  source = "${path.module}/packer/${var.platform == "Windows" ? "windows" : "linux"}/template.pkr.hcl"
  etag   = filemd5("${path.module}/packer/${var.platform == "Windows" ? "windows" : "linux"}/template.pkr.hcl")
}

# Upload Ansible playbooks to S3
resource "aws_s3_object" "ansible_playbook" {
  bucket = module.s3_artifacts.bucket_id
  key    = "ansible/playbooks/site.yml"
  source = "${path.module}/ansible/site.yml"
  etag   = filemd5("${path.module}/ansible/site.yml")
}

resource "aws_s3_object" "ansible_requirements" {
  bucket = module.s3_artifacts.bucket_id
  key    = "ansible/requirements.yml"
  source = "${path.module}/ansible/requirements.yml"
  etag   = filemd5("${path.module}/ansible/requirements.yml")
}

# ── EC2 Image Builder pipeline (Ansible via S3) ───────────────────────────
module "image_builder" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  platform    = var.platform
  kms_key_arn = module.kms.key_arns["image_builder"]

  recipe_version               = var.recipe_version
  root_volume_size             = var.root_volume_size
  instance_types               = var.instance_types
  subnet_id                    = var.subnet_id
  security_group_ids           = var.security_group_ids
  pipeline_schedule_expression = var.pipeline_schedule_expression
  pipeline_enabled             = var.pipeline_enabled
  distribution_regions         = var.distribution_regions

  # Inline component: download + run Ansible from S3
  custom_components = {
    ansible_bootstrap = {
      platform    = var.platform
      version     = var.recipe_version
      description = "Download Ansible playbooks from S3 and run site.yml"
      data = var.platform == "Linux" ? templatefile("${path.module}/components/linux_ansible.yml.tpl", {
        s3_bucket = module.s3_artifacts.bucket_id
        s3_prefix = "ansible"
        region    = var.aws_region
        }) : templatefile("${path.module}/components/windows_ansible.yml.tpl", {
        s3_bucket = module.s3_artifacts.bucket_id
        s3_prefix = "ansible"
        region    = var.aws_region
      })
    }
  }
}

# ── IAM: allow Image Builder instance to read from S3 artifacts bucket ────
resource "aws_iam_role_policy" "s3_read" {
  name = "${var.name}-s3-artifacts-read"
  role = split("/", module.image_builder.instance_profile_arn)[1]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        module.s3_artifacts.bucket_arn,
        "${module.s3_artifacts.bucket_arn}/*"
      ]
    }]
  })
}
