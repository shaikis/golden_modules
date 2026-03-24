# tf-aws-data-e-lakeformation

Production-grade Terraform module for **AWS Lake Formation** — fine-grained data access control, attribute-based access (LF-Tags), row/column-level security, and governed S3 data lake registration.

## Features

- Register S3 locations as Lake Formation data lake resources
- Manage Lake Formation data lake settings (admins, default permissions)
- Create and assign LF-Tags for attribute-based access control (ABAC)
- Grant fine-grained permissions on databases, tables, columns, and data locations
- Data cell filters for row-level and column-level security
- Assign LF-Tags to databases and tables (governed tables)
- Optional IAM role creation for Lake Formation service access
- BYO IAM role and KMS key (from external modules)
- All feature gates default to `false` — opt-in only
- `for_each` throughout — no `count` anti-patterns

## Module Structure

| File | Purpose |
|---|---|
| `settings.tf` | Lake Formation data lake settings (admins, default permissions) |
| `resources.tf` | S3 data lake resource registration |
| `permissions.tf` | Fine-grained Lake Formation permissions |
| `tags.tf` | LF-Tags and LF-Tag policy permissions |
| `data_filters.tf` | Data cell filters (row + column security) |
| `governed_tables.tf` | LF-Tag assignments to databases and tables |
| `iam.tf` | IAM role for Lake Formation service |

## Usage Scenarios

### 1. Register an S3 Data Lake

Register an S3 bucket as a Lake Formation managed data lake location.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  data_lake_admins = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]

  data_lake_locations = {
    raw = {
      s3_arn                  = "arn:aws:s3:::my-datalake-raw"
      use_service_linked_role = false
    }
  }
}
```

### 2. Fine-Grained Table Access

Grant SELECT on specific tables to an analyst role.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_permissions = true

  permissions = {
    analyst_orders = {
      principal   = "arn:aws:iam::123456789012:role/DataAnalyst"
      permissions = ["SELECT", "DESCRIBE"]
      table = {
        database_name = "sales_db"
        name          = "orders"
      }
    }
  }
}
```

### 3. Column-Level PII Masking

Exclude sensitive PII columns (SSN, email) from analyst access.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_permissions = true

  permissions = {
    analyst_pii_safe = {
      principal   = "arn:aws:iam::123456789012:role/DataAnalyst"
      permissions = ["SELECT"]
      table_with_columns = {
        database_name         = "customers_db"
        name                  = "profiles"
        excluded_column_names = ["ssn", "email", "date_of_birth"]
      }
    }
  }
}
```

### 4. Row-Level Multi-Tenant Isolation

Use data cell filters so each tenant sees only their own rows.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_data_filters = true

  data_cell_filters = {
    tenant_a = {
      database_name         = "saas_db"
      table_name            = "events"
      name                  = "tenant_a_filter"
      row_filter_expression = "tenant_id = 'tenant-a'"
    }
    tenant_b = {
      database_name         = "saas_db"
      table_name            = "events"
      name                  = "tenant_b_filter"
      row_filter_expression = "tenant_id = 'tenant-b'"
    }
  }
}
```

### 5. LF-Tag ABAC for Team-Based Access

Tag databases and tables, then grant permissions based on tag expressions.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_lf_tags = true

  lf_tags = {
    team        = { values = ["finance", "marketing", "engineering"] }
    sensitivity = { values = ["public", "internal", "confidential"] }
  }

  lf_tag_policies = {
    finance_read = {
      principal     = "arn:aws:iam::123456789012:role/FinanceAnalyst"
      resource_type = "TABLE"
      permissions   = ["SELECT", "DESCRIBE"]
      expression = [
        { key = "team", values = ["finance"] },
        { key = "sensitivity", values = ["public", "internal"] },
      ]
    }
  }

  create_governed_tables = true

  resource_lf_tags = {
    finance_revenue_table = {
      table = {
        database_name = "finance_db"
        name          = "revenue"
      }
      lf_tags = [
        { key = "team", value = "finance" },
        { key = "sensitivity", value = "confidential" },
      ]
    }
  }
}
```

### 6. Cross-Account Data Sharing

Grant a role in another account access to a table.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_permissions = true

  permissions = {
    cross_account_select = {
      principal   = "arn:aws:iam::987654321098:role/ConsumerRole"
      permissions = ["SELECT", "DESCRIBE"]
      permissions_with_grant_option = []
      table = {
        database_name = "shared_db"
        name          = "public_data"
        catalog_id    = "123456789012"
      }
    }
  }
}
```

### 7. Governed Tables with ACID Transactions

Register multiple S3 zones and assign LF-Tags for governed table management.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  data_lake_locations = {
    bronze = { s3_arn = "arn:aws:s3:::datalake-bronze" }
    silver = { s3_arn = "arn:aws:s3:::datalake-silver" }
    gold   = { s3_arn = "arn:aws:s3:::datalake-gold" }
  }

  create_lf_tags     = true
  create_governed_tables = true

  lf_tags = {
    zone = { values = ["bronze", "silver", "gold"] }
  }

  resource_lf_tags = {
    bronze_events = {
      table = { database_name = "raw_db", name = "events" }
      lf_tags = [{ key = "zone", value = "bronze" }]
    }
  }
}
```

### 8. Lake Formation + EMR

Allow EMR on EC2 to filter data through Lake Formation using external data filtering.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  allow_external_data_filtering      = true
  external_data_filtering_allow_list = ["123456789012"]
  authorized_session_tag_value_list  = ["EMR"]
}
```

### 9. Lake Formation + Athena

Grant Athena workgroup users fine-grained access.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_permissions = true

  permissions = {
    athena_analyst_db = {
      principal   = "arn:aws:iam::123456789012:role/AthenaAnalyst"
      permissions = ["DESCRIBE"]
      database    = { name = "analytics_db" }
    }
    athena_analyst_table = {
      principal   = "arn:aws:iam::123456789012:role/AthenaAnalyst"
      permissions = ["SELECT"]
      table = {
        database_name = "analytics_db"
        wildcard      = true
      }
    }
  }
}
```

### 10. Lake Formation + Redshift Spectrum

Grant Redshift Spectrum IAM role access to external tables.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  create_permissions = true

  permissions = {
    redshift_spectrum = {
      principal   = "arn:aws:iam::123456789012:role/RedshiftSpectrumRole"
      permissions = ["SELECT", "DESCRIBE"]
      table = {
        database_name = "spectrum_db"
        wildcard      = true
      }
    }
  }
}
```

### 11. Replacing IAM + S3 Bucket Policies

Transition from S3 bucket policies to Lake Formation-managed access.

```hcl
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  data_lake_locations = {
    main = {
      s3_arn                  = "arn:aws:s3:::company-datalake"
      use_service_linked_role = false
      hybrid_access_enabled   = true   # coexistence with existing IAM policies during migration
    }
  }

  data_lake_admins = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]

  create_permissions = true

  permissions = {
    revoke_iam_passthrough = {
      principal   = "IAM_ALLOWED_PRINCIPALS"
      permissions = ["DESCRIBE"]
      database    = { name = "main_db" }
    }
  }
}
```

### 12. Audit Data Access with CloudTrail

All Lake Formation API calls are logged automatically via AWS CloudTrail. Enable data event logging.

```hcl
# Enable CloudTrail data events for Lake Formation in your CloudTrail trail:
resource "aws_cloudtrail" "datalake_audit" {
  name           = "datalake-audit"
  s3_bucket_name = "my-cloudtrail-bucket"

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Glue::Table"
      values = ["arn:aws:glue:us-east-1:123456789012:table/"]
    }
  }
}

# Then use the Lake Formation module normally — all GetTableObjects,
# GetWorkUnits, and permission checks are logged to CloudTrail.
module "lakeformation" {
  source = "github.com/your-org/tf-aws-data-e-lakeformation"

  data_lake_admins = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]
  data_lake_locations = {
    main = { s3_arn = "arn:aws:s3:::company-datalake" }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `create_permissions` | Create Lake Formation permissions | `bool` | `false` | no |
| `create_lf_tags` | Create LF-Tags for ABAC | `bool` | `false` | no |
| `create_data_filters` | Create data cell filters | `bool` | `false` | no |
| `create_governed_tables` | Create LF-Tag assignments | `bool` | `false` | no |
| `create_iam_role` | Create IAM role for Lake Formation | `bool` | `true` | no |
| `role_arn` | Existing IAM role ARN (BYO) | `string` | `null` | no |
| `kms_key_arn` | KMS key ARN (BYO) | `string` | `null` | no |
| `data_lake_admins` | IAM ARNs of Lake Formation admins | `list(string)` | `[]` | no |
| `data_lake_locations` | S3 locations to register | `map(object)` | `{}` | no |
| `lf_tags` | LF-Tags to create | `map(object)` | `{}` | no |
| `lf_tag_policies` | LF-Tag policy permissions | `map(object)` | `{}` | no |
| `permissions` | Fine-grained permissions | `map(object)` | `{}` | no |
| `data_cell_filters` | Data cell filters | `map(object)` | `{}` | no |
| `resource_lf_tags` | LF-Tag assignments | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `registered_location_arns` | Map of registered S3 location ARNs |
| `lf_tag_ids` | Map of LF-Tag IDs |
| `permission_ids` | Map of permission IDs |
| `data_filter_ids` | Map of data cell filter IDs |
| `resource_lf_tag_ids` | Map of resource LF-tag assignment IDs |
| `lakeformation_role_arn` | ARN of the Lake Formation IAM service role |
| `aws_account_id` | AWS account ID |
| `aws_region` | AWS region |

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3.0 |
| aws | >= 5.0.0 |
