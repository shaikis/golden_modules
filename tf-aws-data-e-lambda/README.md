# tf-aws-lambda

Terraform module for AWS Lambda functions.

## Features

- Auto-creates execution IAM role with configurable policies
- VPC support (auto-attaches VPC execution policy)
- KMS encryption for environment variables
- X-Ray tracing enabled by default
- CloudWatch log group with configurable retention and KMS
- `publish = true` with alias support
- Event source mappings (SQS, DynamoDB, Kinesis)
- Lambda permissions/triggers map
- Dead letter queue (SQS/SNS)
- Lambda layers support

## Security Controls

| Control | Default |
|---------|---------|
| X-Ray tracing | `Active` |
| KMS env var encryption | Optional (`kms_key_arn`) |
| Log retention | 30 days |
| Reserved concurrency | `-1` (no throttle; set explicitly for prod) |
| VPC | Optional |

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "lambda" {
  source        = "git::https://github.com/your-org/tf-modules.git//tf-aws-lambda?ref=v1.0.0"
  function_name = "data-processor"
  handler       = "app.handler"
  runtime       = "python3.12"
  filename      = "${path.module}/package.zip"
  source_code_hash = filebase64sha256("${path.module}/package.zip")
  kms_key_arn   = module.kms.key_arn
}
```

## Examples

- [Basic](examples/basic/)
- [Complete](examples/complete/)

