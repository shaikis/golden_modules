# AWS Terraform Modules

Production-grade, security-hardened Terraform modules for AWS services.

## Module Catalog

| Module | Description |
|--------|-------------|
| [tf-aws-kms](tf-aws-kms/) | KMS keys, aliases, grants, key policies |
| [tf-aws-vpc](tf-aws-vpc/) | VPC, subnets (public/private/database), NAT, flow logs, endpoints |
| [tf-aws-s3](tf-aws-s3/) | S3 buckets with versioning, encryption, lifecycle, logging |
| [tf-aws-ec2](tf-aws-ec2/) | EC2 instances (on-demand & spot), encrypted EBS, IMDSv2 |
| [tf-aws-rds](tf-aws-rds/) | RDS instances (all engines), Multi-AZ, Performance Insights |
| [tf-aws-eks](tf-aws-eks/) | EKS cluster, managed node groups, Fargate, IRSA |
| [tf-aws-ecs](tf-aws-ecs/) | ECS cluster, Fargate task definitions & services |
| [tf-aws-iam-role](tf-aws-iam-role/) | IAM roles with trust policy, managed/inline policies, instance profiles |
| [tf-aws-lambda](tf-aws-lambda/) | Lambda functions, aliases, event source mappings |
| [tf-aws-alb](tf-aws-alb/) | ALB/NLB with target groups, listeners, WAF |
| [tf-aws-sqs](tf-aws-sqs/) | SQS queues (standard & FIFO), DLQ, KMS |
| [tf-aws-sns](tf-aws-sns/) | SNS topics (standard & FIFO), subscriptions |
| [tf-aws-secretsmanager](tf-aws-secretsmanager/) | Secrets Manager with rotation, replication |
| [tf-aws-elasticache](tf-aws-elasticache/) | ElastiCache Redis (cluster/replication) & Memcached |
| [tf-aws-security-group](tf-aws-security-group/) | Security groups with per-rule resources |
| [tf-aws-rds-aurora](tf-aws-rds-aurora/) | Aurora MySQL/PostgreSQL, Serverless v2, Global Cluster, auto-scaling |
| [tf-aws-s3-replication](tf-aws-s3-replication/) | S3 SRR (same-region) + CRR (cross-region) replication, AWS Backup |
| [tf-aws-transit-gateway](tf-aws-transit-gateway/) | Transit Gateway, VPC attachments, custom route tables, RAM sharing |
| [tf-aws-vpn](tf-aws-vpn/) | Site-to-Site VPN (IKEv2, TGW/VGW) + Client VPN (mTLS/SAML) |
| [tf-aws-asg](tf-aws-asg/) | Auto Scaling Groups, Linux + Windows, unique hostnames, all scaling policies |
| [tf-aws-asg-instance-ops](tf-aws-asg-instance-ops/) | Per-instance standby, scale-in protection, detach utility |
| [tf-aws-ecr](tf-aws-ecr/) | ECR repositories, lifecycle policies, cross-account access, replication |
| [tf-aws-ebs](tf-aws-ebs/) | EBS volume creation, attachment, snapshots, DLM lifecycle policies |
| [tf-aws-eni](tf-aws-eni/) | Elastic Network Interfaces, attachment, Elastic IPs |
| [tf-aws-image-builder](tf-aws-image-builder/) | EC2 Image Builder pipelines (Linux + Windows), Packer/Ansible, software options |
| [tf-aws-fsx](tf-aws-fsx/) | FSx for Windows, Lustre, NetApp ONTAP (SVMs, junction paths, AD), OpenZFS |
| [tf-aws-vpc-endpoints](tf-aws-vpc-endpoints/) | VPC Interface + Gateway endpoints (S3, SSM, ECR, KMS, Secrets Manager, etc.) |
| [tf-aws-bedrock](tf-aws-bedrock/) | Bedrock guardrails, knowledge bases, agents, model invocation logging |

---

## Environment Strategy

Every module example ships with per-environment `.tfvars` files. Switch environments by passing the appropriate file:

```bash
terraform apply -var-file="dev.tfvars"      # dev/staging/qa — shared lower-env VPC
terraform apply -var-file="staging.tfvars"  # staging — same VPC as dev, different label
terraform apply -var-file="prod.tfvars"     # prod — dedicated VPC
```

**VPC sharing rule:** `dev`, `staging`, and `qa` reference the **same** VPC ID and subnets. Only `prod` has a dedicated VPC. This is enforced in all `.tfvars` files — only the `vpc_id` and `subnet_ids` values differ between prod and non-prod.

---

## Design Principles

### 1. Resource Safety — Nothing Gets Destroyed by Accident

All **stateful** resources include:

```hcl
lifecycle {
  prevent_destroy = true
}
```

To intentionally destroy: remove `prevent_destroy`, `terraform apply`, then `terraform destroy`.

### 2. Re-apply Safety — No Spurious Replacements

| Risk | Mitigation |
|------|------------|
| AMI drift on EC2 | `ignore_changes = [ami]` |
| Desired count changed by Auto Scaling | `ignore_changes = [desired_count]` |
| EKS node group scaled by CA | `ignore_changes = [scaling_config[0].desired_size]` |
| RDS password rotated externally | `ignore_changes = [password]` |
| Secret value updated by app | `ignore_changes = [secret_string]` |
| Auth token rotation | `ignore_changes = [auth_token]` |
| Tag drift from external systems | `ignore_changes = [tags["CreatedDate"]]` |

### 3. Version Safety — Creating v2 Without Touching v1

```hcl
# v1 (existing)
module "rds_v1" {
  source = "git::https://github.com/org/tf-modules.git//tf-aws-rds?ref=v1.0.0"
  name   = "app-db-v1"
  ...
}

# v2 (new) — completely separate state, v1 untouched
module "rds_v2" {
  source = "git::https://github.com/org/tf-modules.git//tf-aws-rds?ref=v2.0.0"
  name   = "app-db-v2"
  ...
}
```

When **refactoring module paths** in the same codebase, use `moved {}` blocks:

```hcl
moved {
  from = module.old_name
  to   = module.new_name
}
```

### 4. KMS Encryption — Every Service

All modules accept a `kms_key_id` / `kms_key_arn` variable. The recommended pattern:

```hcl
module "kms" {
  source      = "./tf-aws-kms"
  name        = "app-platform"
  environment = "prod"
}

module "rds" {
  source     = "./tf-aws-rds"
  kms_key_id = module.kms.key_arn
  ...
}

module "s3" {
  source            = "./tf-aws-s3"
  kms_master_key_id = module.kms.key_arn
  ...
}
```

### 5. Tagging Strategy

All modules emit a consistent tag set:

```hcl
tags = {
  Name        = "<derived-resource-name>"
  Environment = var.environment     # dev / staging / prod
  Project     = var.project
  Owner       = var.owner           # team or individual
  CostCenter  = var.cost_center
  ManagedBy   = "terraform"
  Module      = "tf-aws-<service>"
}
```

Additional project-specific tags are merged via:

```hcl
tags = {
  DataClassification = "Confidential"
  Compliance         = "SOC2"
}
```

### 6. Security Controls (All Modules)

| Standard | Controls |
|----------|---------|
| CIS AWS Benchmark | S3 public access block, EC2 IMDSv2, RDS deletion protection, KMS rotation |
| AWS Security Hub (FSBP) | CloudWatch flow logs, RDS Multi-AZ, EKS private endpoint |
| tfsec / checkov pass | No hardcoded credentials, no wildcard IAM, no public S3, encrypted storage |
| SOC 2 / PCI-DSS | KMS everywhere, access logging, audit trails, retention policies |

### 7. `for_each` Over `count`

All multi-item resources (subnets, node groups, rules, etc.) use `for_each` keyed by a **stable string** (AZ name, map key). This means:

- Adding a new item **never** destroys existing items (no index shift).
- Removing an item destroys **only that item**.

---

## Module Versioning

Tag releases with semantic versions:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Reference in calling code:

```hcl
source = "git::https://github.com/your-org/tf-modules.git//tf-aws-vpc?ref=v1.0.0"
```

---

## Quick Start

```hcl
# 1. KMS key (shared)
module "kms" {
  source      = "./tf-aws-kms"
  name        = "platform"
  environment = "prod"
  project     = "my-project"
  owner       = "platform-team"
}

# 2. VPC
module "vpc" {
  source             = "./tf-aws-vpc"
  name               = "platform"
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cidr_block         = "10.10.0.0/16"
  public_subnet_cidrs   = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
  database_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]
  flow_log_kms_key_id   = module.kms.key_arn
}

# 3. RDS
module "rds" {
  source               = "./tf-aws-rds"
  name                 = "app-db"
  environment          = "prod"
  db_name              = "appdb"
  db_subnet_group_name = module.vpc.database_subnet_group_name
  kms_key_id           = module.kms.key_arn
}
```

---

## Requirements

- Terraform >= 1.3.0
- AWS provider >= 5.0
- For EKS: TLS provider >= 4.0

## Security Scanning

Run before every `terraform apply`:

```bash
# tfsec
tfsec .

# checkov
checkov -d .

# terraform validate
terraform validate
```
