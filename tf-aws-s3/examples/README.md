# tf-aws-s3 — Examples

> Quick-start examples for the `tf-aws-s3` Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal config — creates a single S3 bucket with default security settings (AES256 encryption, all public access blocked, versioning enabled) using only required tags |
| [complete](complete/) | Full config — S3 bucket with KMS encryption, versioning, MFA delete, access logging to a dedicated log bucket, lifecycle rules, Intelligent-Tiering, and all public access controls explicitly set |

## Architecture

```mermaid
graph TB
    subgraph basic["basic example"]
        B_Bucket["aws_s3_bucket\n(bucket_name)"]
        B_PAB["Public Access Block\n(all = true)"]
        B_SSE["SSE-AES256\n(default)"]
        B_Ver["Versioning\n(enabled)"]
        B_Bucket --> B_PAB
        B_Bucket --> B_SSE
        B_Bucket --> B_Ver
    end

    subgraph complete["complete example"]
        C_KMS["aws_kms_key\n(tf-aws-kms module)"]
        C_LogBucket["S3 Log Bucket\n(s3_logs module)\nSSE-AES256"]
        C_Bucket["aws_s3_bucket\n(main bucket)"]
        C_PAB["Public Access Block\n(all = true)"]
        C_SSE["SSE-KMS\n(bucket key enabled)"]
        C_Ver["Versioning + MFA Delete"]
        C_Log["Access Logging\n→ log bucket"]
        C_LC["Lifecycle Rules\n(transitions + expiration)"]
        C_IT["Intelligent-Tiering\nconfiguration"]

        C_KMS -->|"encrypt with"| C_SSE
        C_Bucket --> C_PAB
        C_Bucket --> C_SSE
        C_Bucket --> C_Ver
        C_Bucket --> C_Log
        C_Bucket --> C_LC
        C_Bucket --> C_IT
        C_Log -->|"write logs to"| C_LogBucket
    end
```

## Running an Example

```bash
cd basic
terraform init
terraform apply -var-file="dev.tfvars"
```

```bash
cd complete
terraform init
terraform apply -var-file="dev.tfvars"
```
