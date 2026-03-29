# tf-aws-s3-access-points

Terraform module for AWS S3 Access Points on standard S3 buckets.

## Scope

This module manages standard `aws_s3_access_point` resources for S3 buckets.

It does not currently cover:
- S3 access points for FSx for OpenZFS
- Multi-Region Access Points
- S3 Access Grants
- S3 Object Lambda access points

## Requirements

- Terraform `>= 1.3.0`
- AWS provider `>= 5.0`

## Features

- Multiple access points per bucket
- Optional VPC-only access points
- Optional inline access point policy
- Optional access point public access block controls
- Common tags plus per-access-point tags

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "s3_access_points" {
  source = "../tf-aws-s3-access-points"

  bucket = "my-app-bucket"

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }

  access_points = [
    {
      name = "app-shared"
      public_access_block_configuration = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    },
    {
      name   = "app-private"
      vpc_id = "vpc-12345678"
    }
  ]
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket` | `string` | n/a | Name of the S3 bucket for which access points will be created. |
| `bucket_account_id` | `string` | `null` | Optional account ID that owns the bucket. |
| `access_points` | `list(object(...))` | `[]` | Access point definitions, including optional `policy`, `vpc_id`, `public_access_block_configuration`, and `tags`. |
| `tags` | `map(string)` | `{}` | Common tags applied to all access points. |

## Outputs

| Name | Description |
|------|-------------|
| `access_point_arns` | ARNs of the created access points keyed by name. |
| `access_point_aliases` | Aliases of the created access points keyed by name. |
| `access_point_domain_names` | Domain names of the created access points keyed by name. |
| `access_point_endpoints` | Endpoints of the created access points keyed by name. |

## Example

- [Basic example](examples/basic/)

## Notes

- This module expects the target bucket to already exist or to be created in the same configuration.
- AWS access point names must be unique within the account and Region for the bucket context you use.
- If you need FSx for OpenZFS S3 access points, use a separate module or custom implementation path.

