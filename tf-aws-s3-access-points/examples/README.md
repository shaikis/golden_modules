# tf-aws-s3-access-points — Examples

> Quick-start examples for the `tf-aws-s3-access-points` Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal config — creates an S3 bucket alongside two access points: a shared access point (all public access blocked) and a private VPC-restricted access point |

## Architecture

```mermaid
graph TB
    AppClient([Application / IAM Principal])
    VPCClient([VPC-only Client])

    subgraph basic["basic example"]
        S3Bucket["aws_s3_bucket\n(example bucket)"]

        subgraph AccessPoints["tf-aws-s3-access-points module"]
            AP_Shared["Access Point: project-shared\nPublic access block: all true"]
            AP_Private["Access Point: project-private\nvpc_configuration = var.vpc_id"]
        end

        S3Bucket --> AP_Shared
        S3Bucket --> AP_Private
    end

    VPC["Amazon VPC\n(var.vpc_id)"]

    AppClient -->|"ARN-scoped requests"| AP_Shared
    VPCClient -->|"VPC-only requests"| AP_Private
    AP_Private -->|"restricted to"| VPC
```

## Running an Example

```bash
cd basic
terraform init
terraform apply -var-file="dev.tfvars"
```
