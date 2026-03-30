# tf-aws-s3

Terraform module for AWS S3 with security-hardened defaults.

## Features

- KMS or AES256 server-side encryption (bucket key enabled by default)
- Versioning with optional MFA delete
- Block all public access by default
- Mandatory deny-HTTP and require-TLS-1.2 bucket policies
- Access logging to a target bucket
- Flexible lifecycle rules (transitions + expiration)
- CORS rules
- Static website hosting
- S3 Object Lock (WORM)
- Cross-region replication
- Event notifications (Lambda / SQS / SNS)
- Intelligent-Tiering configuration
- `prevent_destroy` lifecycle guard

## Security Controls

| Control | Default |
|---------|---------|
| Server-side encryption | `aws:kms` |
| Block public access | All 4 settings = `true` |
| Deny HTTP requests | Yes |
| Require TLS 1.2+ | Yes |
| Versioning | Enabled |
| Access logging | Opt-in |
| Object Lock | Opt-in |

## Architecture

```mermaid
graph TB
    Client([Client / Application])

    subgraph S3_Module["tf-aws-s3 Module"]
        Bucket["aws_s3_bucket\n(S3 Bucket)"]
        Ownership["aws_s3_bucket_ownership_controls"]
        PAB["aws_s3_bucket_public_access_block\n(All public access blocked)"]
        Versioning["aws_s3_bucket_versioning\n(Enabled + optional MFA Delete)"]
        SSE["aws_s3_bucket_server_side_encryption_configuration\n(KMS or AES256)"]
        Policy["aws_s3_bucket_policy\n(Deny HTTP + Require TLS 1.2)"]
        Logging["aws_s3_bucket_logging\n(Access Log Target Bucket)"]
        Lifecycle["aws_s3_bucket_lifecycle_configuration\n(Transitions + Expiration)"]
        Tiering["aws_s3_intelligent_tiering_configuration"]
        ObjectLock["aws_s3_bucket_object_lock_configuration\n(WORM — optional)"]
        Notification["aws_s3_bucket_notification\n(Lambda / SQS / SNS)"]
    end

    KMS["aws_kms_key\n(Customer Managed Key)"]
    LogBucket["S3 Access Log Bucket"]
    Lambda["AWS Lambda"]
    SQS["Amazon SQS"]
    SNS["Amazon SNS"]

    Client -->|"HTTPS only (TLS 1.2+)"| Bucket
    Bucket --> Ownership
    Bucket --> PAB
    Bucket --> Versioning
    Bucket --> SSE
    Bucket --> Policy
    Bucket --> Lifecycle
    Bucket --> Tiering
    Bucket --> ObjectLock
    Bucket --> Notification
    SSE -->|"encrypt with"| KMS
    Logging -->|"write logs to"| LogBucket
    Notification -->|"event"| Lambda
    Notification -->|"event"| SQS
    Notification -->|"event"| SNS
```

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "s3" {
  source = "git::https://github.com/your-org/tf-modules.git//tf-aws-s3?ref=v1.0.0"

  bucket_name       = "my-app-data"
  environment       = "prod"
  kms_master_key_id = module.kms.key_arn
}
```

## Version Safety

- `prevent_destroy = true` prevents accidental deletion.
- Changing `bucket_name` creates a **new** bucket (S3 names are immutable). Plan carefully.
- Use `moved {}` if renaming the module block in calling code.

## Examples

- [Basic](examples/basic/)
- [Complete](examples/complete/) — KMS, lifecycle, logging, intelligent-tiering

