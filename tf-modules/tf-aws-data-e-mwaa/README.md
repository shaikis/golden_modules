# tf-aws-data-e-mwaa

Production-grade Terraform module for Amazon Managed Workflows for Apache Airflow (MWAA) — environments, IAM, and CloudWatch alarms.

## Features

- Map-driven `aws_mwaa_environment` resources with `for_each`
- Full logging configuration per component (dag_processing, scheduler, task, webserver, worker)
- Auto-created execution IAM role with granular service permission toggles
- BYO role via `role_arn` (from `tf-aws-iam`)
- BYO KMS key via `kms_key_arn` (from `tf-aws-kms`)
- CloudWatch alarms for scheduler health, task queue depth, DAG parse time, DLQ (opt-in)
- PRIVATE_ONLY webserver enforced by default
- Airflow configuration overrides via `airflow_configuration_options`
- Secrets Manager backend support through configuration options
- Requirements and plugins versioning via S3 object versions

## Usage

### Minimal

```hcl
module "mwaa" {
  source = "git::https://github.com/your-org/tf-aws-data-e-mwaa.git"

  environments = {
    data_platform = {
      source_bucket_arn  = "arn:aws:s3:::my-mwaa-bucket"
      subnet_ids         = ["subnet-private-a", "subnet-private-b"]
      security_group_ids = ["sg-mwaa"]
    }
  }
}
```

### With full logging and alarms

```hcl
module "mwaa" {
  source = "git::https://github.com/your-org/tf-aws-data-e-mwaa.git"

  create_alarms       = true
  alarm_sns_topic_arn = "arn:aws:sns:us-east-1:...:alerts"

  environments = {
    prod = {
      source_bucket_arn = "arn:aws:s3:::prod-dags"
      subnet_ids        = ["subnet-a", "subnet-b"]
      security_group_ids = ["sg-mwaa"]
      dag_processing_logs_level = "WARNING"
      scheduler_logs_level      = "WARNING"
      task_logs_level           = "INFO"
    }
  }
}
```

### BYO IAM role

```hcl
module "mwaa" {
  source = "git::https://github.com/your-org/tf-aws-data-e-mwaa.git"

  create_iam_role = false
  role_arn        = module.iam.role_arn  # from tf-aws-iam

  environments = {
    prod = {
      source_bucket_arn  = "arn:aws:s3:::my-bucket"
      subnet_ids         = ["subnet-a", "subnet-b"]
      security_group_ids = ["sg-mwaa"]
    }
  }
}
```

---

## Scenarios

### 1. ETL DAG Orchestration

Orchestrate multi-step ETL pipelines in Airflow DAGs using operators for Glue, EMR, and Redshift. Enable `enable_glue_permissions = true` and `enable_redshift_permissions = true`. Use the `GlueJobOperator` and `RedshiftDataOperator` from the `apache-airflow-providers-amazon` package in `requirements.txt`.

```hcl
module "mwaa" {
  source                      = "../../"
  enable_glue_permissions     = true
  enable_redshift_permissions = true
  environments = {
    etl = {
      source_bucket_arn  = "arn:aws:s3:::etl-dags"
      subnet_ids         = ["subnet-a", "subnet-b"]
      security_group_ids = ["sg-mwaa"]
      requirements_s3_path = "requirements/requirements.txt"
    }
  }
}
```

### 2. ML Pipeline DAGs

Schedule and monitor SageMaker training jobs, processing jobs, and pipeline executions from Airflow DAGs. Enable `enable_sagemaker_permissions = true`. Use `SageMakerTrainingOperator` and `SageMakerPipelineOperator`.

```hcl
module "mwaa" {
  source                       = "../../"
  enable_sagemaker_permissions = true
  environments = {
    ml_platform = {
      environment_class  = "mw1.large"
      source_bucket_arn  = "arn:aws:s3:::ml-dags"
      subnet_ids         = ["subnet-a", "subnet-b"]
      security_group_ids = ["sg-mwaa"]
    }
  }
}
```

### 3. Cross-Service Orchestration

Orchestrate across Glue, EMR, Redshift, SageMaker, Lambda, and Step Functions in a single DAG. Enable all required permission flags. Design DAGs with `TaskGroup` to logically group related service calls and expose dependencies clearly.

```hcl
module "mwaa" {
  source                       = "../../"
  enable_glue_permissions      = true
  enable_emr_permissions       = true
  enable_redshift_permissions  = true
  enable_sagemaker_permissions = true
  enable_lambda_permissions    = true
  enable_sfn_permissions       = true
  environments = { ... }
}
```

### 4. Secrets Management for DB Connections

Store Airflow connections and variables in AWS Secrets Manager using the `SecretsManagerBackend`. Configure via `airflow_configuration_options`. Secrets under `airflow/connections/*` are automatically resolved by Airflow operators.

```hcl
airflow_configuration_options = {
  "secrets.backend" = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
  "secrets.backend_kwargs" = jsonencode({
    connections_prefix = "airflow/connections"
    variables_prefix   = "airflow/variables"
    sep                = "/"
  })
}
```

The module grants `secretsmanager:GetSecretValue` on `arn:aws:secretsmanager:*:*:secret:airflow/*` by default.

### 5. Custom Operators

Package custom operators in a `plugins.zip` and upload to S3. Reference via `plugins_s3_path` and optionally pin a specific version with `plugins_s3_object_version` to prevent unexpected operator updates. Custom operators appear in the Airflow plugin manager automatically.

```hcl
environments = {
  prod = {
    source_bucket_arn           = "arn:aws:s3:::prod-dags"
    plugins_s3_path             = "plugins/plugins.zip"
    plugins_s3_object_version   = "abc123def456"
    subnet_ids                  = ["subnet-a", "subnet-b"]
    security_group_ids          = ["sg-mwaa"]
  }
}
```

### 6. XCom for Data Passing Between Tasks

Use Airflow XCom to pass small datasets or metadata between tasks. For large outputs, write to S3 and pass only the S3 URI via XCom. The MWAA execution role has S3 read/write access to the DAGs bucket by default — extend with additional bucket ARNs using a custom policy attached via `additional_policy_arns`.

```python
# In a DAG
def process_data(**context):
    result = {"s3_path": "s3://bucket/output/file.parquet", "rows": 1000}
    context["task_instance"].xcom_push(key="result", value=result)

def use_data(**context):
    result = context["task_instance"].xcom_pull(task_ids="process_data", key="result")
```

### 7. SLA Monitoring

Define SLAs on DAGs and tasks to trigger alerts when execution exceeds expected duration. Configure `sla_miss_callback` in DAG definition and set up SLA email alerts through Airflow SMTP configuration or SNS via a custom callback.

```python
from airflow import DAG
from datetime import timedelta

dag = DAG(
    "etl_pipeline",
    sla_miss_callback=my_sla_callback,
    default_args={"sla": timedelta(hours=2)},
)
```

### 8. DAG Versioning with S3

Use S3 versioning on the DAGs bucket to maintain DAG history and enable rollback. Pin `requirements_s3_object_version` and `plugins_s3_object_version` in Terraform to enforce exact versions in production, preventing automatic updates when new files are uploaded.

```hcl
environments = {
  prod = {
    source_bucket_arn                = "arn:aws:s3:::prod-dags"
    requirements_s3_path             = "requirements/requirements.txt"
    requirements_s3_object_version   = "VkREJb2YFmSe8VGr3KjjHFPTyXV1stXv"
    plugins_s3_path                  = "plugins/plugins.zip"
    plugins_s3_object_version        = "X3vRpQmT9hLkWuXzYnBcD2EfJqKsM8Na"
    subnet_ids                       = ["subnet-a", "subnet-b"]
    security_group_ids               = ["sg-mwaa"]
  }
}
```

### 9. MWAA + Step Functions Handoff

Trigger Step Functions state machines from Airflow DAGs using the `StepFunctionStartExecutionOperator`. MWAA handles scheduling and dependency management; Step Functions handles complex branching, retries, and service integrations. Enable `enable_sfn_permissions = true`.

```python
from airflow.providers.amazon.aws.operators.step_function import StepFunctionStartExecutionOperator

trigger_sfn = StepFunctionStartExecutionOperator(
    task_id="start_etl_pipeline",
    state_machine_arn="arn:aws:states:us-east-1:...:stateMachine:daily-etl",
    input=json.dumps({"date": "{{ ds }}"}),
    wait_for_completion=True,
)
```

### 10. Cost Optimization with min_workers=1

Set `min_workers = 1` on non-production environments to reduce cost. MWAA auto-scales workers based on task queue depth. Combine with `environment_class = "mw1.small"` for development/staging. Use `alarm_queued_tasks_threshold` to detect when the single worker becomes a bottleneck.

```hcl
environments = {
  dev = {
    environment_class  = "mw1.small"
    min_workers        = 1
    max_workers        = 5
    source_bucket_arn  = "arn:aws:s3:::dev-dags"
    subnet_ids         = ["subnet-a", "subnet-b"]
    security_group_ids = ["sg-mwaa"]
  }
}
```

### 11. PRIVATE_ONLY Security

The module defaults `webserver_access_mode = "PRIVATE_ONLY"` — the Airflow UI is accessible only from within the VPC. Access via VPN, AWS Client VPN, or a bastion host. For `PUBLIC_ONLY`, override explicitly and ensure security groups restrict access to known CIDR ranges.

```hcl
environments = {
  prod = {
    webserver_access_mode  = "PRIVATE_ONLY"  # default — no external access
    subnet_ids             = ["subnet-private-a", "subnet-private-b"]
    security_group_ids     = ["sg-mwaa-strict"]
    source_bucket_arn      = "arn:aws:s3:::prod-dags"
  }
}
```

### 12. Upgrading Airflow Version

Change `airflow_version` in the environment map to trigger an in-place upgrade. MWAA applies the upgrade during the next maintenance window (controlled by `weekly_maintenance_window_start`). Test the upgrade in `dev` first by updating only the dev environment, validating DAGs, then promoting to `prod`.

```hcl
environments = {
  dev = {
    airflow_version   = "2.9.2"  # upgrade dev first
    source_bucket_arn = "arn:aws:s3:::dev-dags"
    subnet_ids        = ["subnet-a", "subnet-b"]
    security_group_ids = ["sg-mwaa"]
  }
  prod = {
    airflow_version   = "2.8.1"  # keep prod on current version until dev validated
    source_bucket_arn = "arn:aws:s3:::prod-dags"
    subnet_ids        = ["subnet-a", "subnet-b"]
    security_group_ids = ["sg-mwaa"]
  }
}
```

---

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_alarms` | Create CloudWatch alarms | `bool` | `false` |
| `create_iam_role` | Create MWAA execution IAM role | `bool` | `true` |
| `role_arn` | BYO IAM role ARN | `string` | `null` |
| `kms_key_arn` | BYO KMS key ARN | `string` | `null` |
| `name_prefix` | Resource name prefix | `string` | `""` |
| `tags` | Default resource tags | `map(string)` | `{}` |
| `alarm_sns_topic_arn` | SNS topic for alarm notifications | `string` | `null` |
| `alarm_queued_tasks_threshold` | QueuedTasks alarm threshold | `number` | `10` |
| `alarm_pending_tasks_threshold` | TasksPending alarm threshold | `number` | `10` |
| `alarm_dag_parse_time_threshold` | DAG parse time alarm threshold (seconds) | `number` | `30` |
| `enable_glue_permissions` | Grant Glue permissions | `bool` | `false` |
| `enable_emr_permissions` | Grant EMR permissions | `bool` | `false` |
| `enable_redshift_permissions` | Grant Redshift permissions | `bool` | `false` |
| `enable_sagemaker_permissions` | Grant SageMaker permissions | `bool` | `false` |
| `enable_batch_permissions` | Grant Batch permissions | `bool` | `false` |
| `enable_lambda_permissions` | Grant Lambda permissions | `bool` | `false` |
| `enable_sfn_permissions` | Grant Step Functions permissions | `bool` | `false` |
| `environments` | Map of MWAA environments to create | `map(object)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `environment_arns` | Map of key => ARN |
| `environment_names` | Map of key => name |
| `webserver_urls` | Map of key => Airflow webserver URL |
| `mwaa_role_arn` | Execution role ARN |
| `alarm_arns` | Map of alarm name => ARN |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |
