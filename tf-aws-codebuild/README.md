# tf-aws-codebuild

Terraform module for AWS CodeBuild. Provisions a fully configured CodeBuild project suitable for Docker container builds and CI/CD pipelines. Includes an auto-created IAM service role with least-privilege permissions, optional CloudWatch Logs and S3 log shipping, VPC support, KMS artifact encryption, and both x86 and ARM64/Graviton build environments.

---

## Features

- Creates `aws_codebuild_project` with all standard configuration surfaces
- Auto-creates an IAM service role with scoped permissions for CloudWatch Logs, ECR push/pull, S3 artifacts, VPC networking, and KMS encryption
- CloudWatch Log Group created and wired automatically when `enable_cloudwatch_logs = true`
- Supports `NO_SOURCE`, `GITHUB`, `GITHUB_ENTERPRISE`, `BITBUCKET`, `CODECOMMIT`, and `S3` source types
- ARM64/Graviton builds via `image_type = "ARM_CONTAINER"`
- Local and S3 build caching
- Inline buildspec or repo-based `buildspec.yml`
- Extensible IAM policy via `additional_policy_statements`

---

## Usage

### Standard x86 Docker Build (GitHub source)

```hcl
module "codebuild_x86" {
  source = "./tf-aws-codebuild"

  name        = "my-app-build"
  name_prefix = "prod"
  description = "Build and push Docker image for my-app (x86)"
  environment = "prod"

  # Source
  source_type     = "GITHUB"
  source_location = "https://github.com/my-org/my-app.git"
  source_version  = "main"
  git_clone_depth = 1

  # Environment — standard Linux x86
  compute_type    = "BUILD_GENERAL1_SMALL"
  image           = "aws/codebuild/standard:7.0"
  image_type      = "LINUX_CONTAINER"
  privileged_mode = true   # required for Docker daemon

  environment_variables = {
    AWS_DEFAULT_REGION = { value = "us-east-1" }
    ECR_REPO_URI       = { value = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app" }
    IMAGE_TAG          = { value = "latest" }
  }

  # Artifacts
  artifacts_type = "NO_ARTIFACTS"

  # Logs
  enable_cloudwatch_logs = true
  log_retention_days     = 30

  # Caching — layer cache speeds up repeated Docker builds
  cache_type  = "LOCAL"
  cache_modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]

  tags = {
    Team    = "platform"
    Project = "my-app"
  }
}
```

---

### ARM64 / Graviton Docker Build

Use `image_type = "ARM_CONTAINER"` together with an aarch64 image to produce native ARM64 container images (e.g., for AWS Graviton ECS/EKS workloads).

```hcl
module "codebuild_arm64" {
  source = "./tf-aws-codebuild"

  name        = "my-app-build-arm64"
  name_prefix = "prod"
  description = "Build and push ARM64 Docker image for my-app (Graviton)"
  environment = "prod"

  # Source
  source_type     = "GITHUB"
  source_location = "https://github.com/my-org/my-app.git"
  source_version  = "main"
  git_clone_depth = 1

  # Environment — ARM64 / Graviton
  compute_type    = "BUILD_GENERAL1_SMALL"
  image           = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
  image_type      = "ARM_CONTAINER"
  privileged_mode = true   # required for Docker daemon

  environment_variables = {
    AWS_DEFAULT_REGION = { value = "us-east-1" }
    ECR_REPO_URI       = { value = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app" }
    IMAGE_TAG          = { value = "arm64-latest" }
    TARGETARCH         = { value = "arm64" }
  }

  # Inline buildspec — override repo file
  buildspec = <<-BUILDSPEC
    version: 0.2
    phases:
      pre_build:
        commands:
          - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
      build:
        commands:
          - docker build --platform linux/arm64 -t $ECR_REPO_URI:$IMAGE_TAG .
      post_build:
        commands:
          - docker push $ECR_REPO_URI:$IMAGE_TAG
  BUILDSPEC

  # Artifacts pushed directly to ECR — no S3 artifacts needed
  artifacts_type = "NO_ARTIFACTS"

  # Logs
  enable_cloudwatch_logs = true
  log_retention_days     = 14

  # Layer cache — meaningful for ARM builds
  cache_type  = "LOCAL"
  cache_modes = ["LOCAL_DOCKER_LAYER_CACHE"]

  tags = {
    Team         = "platform"
    Project      = "my-app"
    Architecture = "arm64"
  }
}
```

---

### VPC Build with S3 Artifacts and KMS Encryption

```hcl
module "codebuild_vpc" {
  source = "./tf-aws-codebuild"

  name        = "internal-build"
  name_prefix = "staging"
  environment = "staging"

  source_type     = "CODECOMMIT"
  source_location = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/internal-app"

  compute_type = "BUILD_GENERAL1_MEDIUM"
  image        = "aws/codebuild/standard:7.0"
  image_type   = "LINUX_CONTAINER"

  # VPC networking
  vpc_id                 = "vpc-0abc123456def7890"
  vpc_subnet_ids         = ["subnet-0aaa111", "subnet-0bbb222"]
  vpc_security_group_ids = ["sg-0ccc333"]

  # Encrypted S3 artifacts
  artifacts_type   = "S3"
  artifacts_bucket = "my-artifact-bucket"
  artifacts_path   = "internal-build/output"
  kms_key_arn      = "arn:aws:kms:us-east-1:123456789012:key/aaaabbbb-cccc-dddd-eeee-ffffffffffff"

  enable_cloudwatch_logs = true
  log_retention_days     = 7

  tags = {
    Team = "security"
  }
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name of the CodeBuild project | `string` | — | yes |
| `name_prefix` | Optional prefix prepended to the name | `string` | `""` | no |
| `description` | Description of the CodeBuild project | `string` | `"Managed by Terraform"` | no |
| `environment` | Deployment environment label (used in tags) | `string` | `"dev"` | no |
| `project` | Project label (used in tags) | `string` | `""` | no |
| `owner` | Owner label (used in tags) | `string` | `""` | no |
| `cost_center` | Cost center label (used in tags) | `string` | `""` | no |
| `tags` | Additional resource tags | `map(string)` | `{}` | no |
| `build_timeout` | Build timeout in minutes | `number` | `60` | no |
| `queued_timeout` | Queued timeout in minutes | `number` | `480` | no |
| `source_type` | Source type: `GITHUB`, `GITHUB_ENTERPRISE`, `BITBUCKET`, `CODECOMMIT`, `S3`, `NO_SOURCE` | `string` | `"NO_SOURCE"` | no |
| `source_location` | Source location URL or S3 URI | `string` | `""` | no |
| `source_version` | Branch, tag, or commit SHA for Git sources | `string` | `null` | no |
| `buildspec` | Inline buildspec YAML. Leave empty to use `buildspec.yml` from source | `string` | `""` | no |
| `git_clone_depth` | Git clone depth. `0` = full clone | `number` | `1` | no |
| `compute_type` | CodeBuild compute type (see validation for valid values) | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| `image` | CodeBuild build image URI | `string` | `"aws/codebuild/standard:7.0"` | no |
| `image_type` | Environment type: `LINUX_CONTAINER`, `ARM_CONTAINER`, `LINUX_GPU_CONTAINER`, `WINDOWS_SERVER_2019_CONTAINER` | `string` | `"LINUX_CONTAINER"` | no |
| `privileged_mode` | Enable privileged mode (required for Docker builds) | `bool` | `false` | no |
| `environment_variables` | Map of `name => { value, type }`. Type: `PLAINTEXT`, `PARAMETER_STORE`, `SECRETS_MANAGER` | `map(object)` | `{}` | no |
| `artifacts_type` | Artifacts type: `NO_ARTIFACTS` or `S3` | `string` | `"NO_ARTIFACTS"` | no |
| `artifacts_bucket` | S3 bucket for artifacts. Required when `artifacts_type = S3` | `string` | `null` | no |
| `artifacts_path` | S3 path prefix for artifacts | `string` | `""` | no |
| `cache_type` | Cache type: `NO_CACHE`, `LOCAL`, `S3` | `string` | `"NO_CACHE"` | no |
| `cache_bucket` | S3 bucket for S3 cache | `string` | `null` | no |
| `cache_modes` | Local cache modes: `LOCAL_SOURCE_CACHE`, `LOCAL_DOCKER_LAYER_CACHE`, `LOCAL_CUSTOM_CACHE` | `list(string)` | `[]` | no |
| `enable_cloudwatch_logs` | Enable CloudWatch Logs for build output | `bool` | `true` | no |
| `log_retention_days` | CloudWatch log retention in days | `number` | `14` | no |
| `enable_s3_logs` | Enable S3 logging for build output | `bool` | `false` | no |
| `s3_logs_bucket` | S3 bucket for build logs | `string` | `null` | no |
| `s3_logs_prefix` | S3 prefix for build logs | `string` | `"codebuild-logs"` | no |
| `vpc_id` | VPC ID for builds inside a VPC. `null` = outside VPC | `string` | `null` | no |
| `vpc_subnet_ids` | Subnet IDs for CodeBuild inside VPC | `list(string)` | `[]` | no |
| `vpc_security_group_ids` | Security group IDs for CodeBuild inside VPC | `list(string)` | `[]` | no |
| `kms_key_arn` | KMS key ARN for encrypting build artifacts | `string` | `null` | no |
| `additional_policy_statements` | Additional IAM policy statements for the CodeBuild service role | `list(object)` | `[]` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `project_name` | Name of the CodeBuild project |
| `project_arn` | ARN of the CodeBuild project |
| `project_id` | ID of the CodeBuild project |
| `service_role_arn` | ARN of the CodeBuild IAM service role |
| `service_role_name` | Name of the CodeBuild IAM service role |
| `log_group_name` | CloudWatch Log Group name for build logs (empty string when CloudWatch logs are disabled) |

---

## Notes

### ARM64 image compatibility

| `image_type` | Recommended `image` |
|---|---|
| `LINUX_CONTAINER` (x86) | `aws/codebuild/standard:7.0` |
| `ARM_CONTAINER` | `aws/codebuild/amazonlinux-aarch64-standard:3.0` |
| `LINUX_GPU_CONTAINER` | `aws/codebuild/standard:7.0` |

### Docker builds

Set `privileged_mode = true` whenever the build needs to run a Docker daemon (e.g., `docker build`, `docker push`). This is required regardless of architecture.

### Secrets in environment variables

Use `type = "PARAMETER_STORE"` or `type = "SECRETS_MANAGER"` instead of `PLAINTEXT` for sensitive values. The module passes the type through directly to CodeBuild; ensure the service role has the appropriate SSM/Secrets Manager permissions via `additional_policy_statements`.

### VPC builds

When `vpc_id` is set, the module automatically appends EC2 networking permissions to the service role policy. Ensure the subnets have a route to the internet (NAT gateway) or use VPC endpoints for CodeBuild to reach AWS APIs.

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0 |
