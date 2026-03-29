# tf-aws-tag-governance

Terraform module to enforce required tags with AWS Config and optional SNS notifications.

## Scope

This module can manage:
- an AWS Config managed rule using `REQUIRED_TAGS`
- optional AWS Config recorder and delivery channel
- optional Config IAM role creation
- optional SNS topic creation
- optional EventBridge notifications for compliance changes

## Features

- Choice-based Config setup: use existing AWS Config foundation or let the module create recorder resources
- Choice-based notifications: create an SNS topic, use an existing one, or disable notifications
- Required tag enforcement for up to 6 tags supported by the AWS managed rule
- Optional value enforcement for each required tag
- Optional scoping by AWS Config resource types

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0` so deployments stay predictable.

## Usage

```hcl
module "tag_governance" {
  source = "git::https://github.com/your-org/tf-modules.git//tf-aws-tag-governance?ref=v1.0.0"

  name        = "backup-tags"
  name_prefix = "prod"
  environment = "prod"

  required_tags = {
    Backup = {
      value = "true"
    }
    BackupPolicy = {
      value = "daily"
    }
    Environment = {
      value = "prod"
    }
  }

  resource_types_scope = [
    "AWS::EC2::Volume",
    "AWS::EC2::Instance",
    "AWS::RDS::DBInstance",
    "AWS::EFS::FileSystem"
  ]

  create_sns_topic                 = true
  create_eventbridge_notifications = true
}
```

## Inputs

| Name | Description |
|------|-------------|
| `name` | Base name for tag governance resources. |
| `name_prefix` | Optional prefix for resource names. |
| `environment` | Environment tag value. |
| `tags` | Additional tags for module-managed resources. |
| `required_tags` | Map of required tags and optional values. Between 1 and 6 tags are supported. |
| `resource_types_scope` | Optional AWS Config resource types to scope the rule. |
| `tag_rule_maximum_execution_frequency` | Optional AWS Config evaluation frequency. |
| `create_sns_topic` | Create an SNS topic for compliance notifications. |
| `sns_topic_arn` | Existing SNS topic ARN for notifications. |
| `sns_kms_key_id` | KMS key for created SNS topic encryption. |
| `create_eventbridge_notifications` | Send AWS Config compliance changes to SNS through EventBridge. |
| `create_config_recorder` | Create AWS Config recorder and delivery channel. |
| `create_config_role` | Create IAM role for AWS Config when recorder creation is enabled. |
| `config_role_arn` | Existing IAM role ARN for AWS Config. |
| `config_s3_bucket_name` | S3 bucket name for AWS Config delivery channel. |
| `config_snapshot_delivery_frequency` | AWS Config snapshot delivery frequency. |
| `include_global_resource_types` | Include global resource types in the recorder. |

## Outputs

| Name | Description |
|------|-------------|
| `config_rule_name` | Name of the AWS Config required tags rule. |
| `config_rule_arn` | ARN of the AWS Config required tags rule. |
| `required_tags` | Required tags enforced by the module. |
| `sns_topic_arn` | SNS topic ARN used for notifications. |
| `config_recorder_name` | AWS Config recorder name when created by this module. |
| `config_delivery_channel_name` | AWS Config delivery channel name when created by this module. |
| `eventbridge_rule_name` | EventBridge rule name for compliance notifications. |

## Design Notes

- This module enforces tag presence and optional values through AWS Config. It does not universally auto-remediate deleted tags across every AWS resource type.
- To make the rule operational, AWS Config must be enabled in the target account and region. You can either let this module create the recorder or point it at an existing AWS Config setup.
- The AWS managed `REQUIRED_TAGS` rule supports up to 6 required tags.
- For production backup governance, a common required tag set is `Backup`, `BackupPolicy`, and `Environment`.

## Example

- [Basic](examples/basic/)
