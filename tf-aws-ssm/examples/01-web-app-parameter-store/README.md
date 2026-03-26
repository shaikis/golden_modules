# Example 1: Three-Tier Web App — SSM Parameter Store

## Scenario

A fintech company runs a three-tier production application:

```
Internet → ALB → ECS Fargate (API) → RDS Aurora PostgreSQL
                                   → ElastiCache Redis
                                   → SQS FIFO Queue
```

All configuration values — database credentials, third-party API keys, feature flags, infrastructure references — live in **SSM Parameter Store**. No secrets appear in Docker images, task definitions, or environment variable literals. ECS tasks fetch parameters at startup via their IAM execution role.

---

## Why SSM Parameter Store Instead of Environment Variables

| Concern | Hardcoded Env Vars | SSM Parameter Store |
|---|---|---|
| Secret rotation | Requires redeployment | Update in SSM, no redeploy |
| Audit trail | None | CloudTrail logs every read |
| Access control | Anyone with task def access | IAM policy per parameter path |
| Secrets in Docker image | Risk of leaking in image layers | Never in image |
| Cross-service sharing | Copy-paste manually | Single source of truth |
| Encryption | Plaintext in task definition | KMS-encrypted SecureString |

---

## Parameter Hierarchy

All parameters follow the naming convention:

```
/<environment>/<app>/<component>/<param-name>
```

Example tree for this fintech app:

```
/prod/fintech-app/
  database/
    host             (String)
    reader_host      (String)
    port             (String)
    name             (String)
    username         (String)
    password         (SecureString)  <-- KMS encrypted
    connection_string (SecureString)
    pool_min         (String)
    pool_max         (String)
  stripe/
    secret_key       (SecureString)
    webhook_secret   (SecureString)
  sendgrid/
    api_key          (SecureString)
  twilio/
    account_sid      (String)
    auth_token       (SecureString)
  app/
    jwt_secret       (SecureString)
    jwt_expiry_minutes (String)
    cors_allowed_origins (StringList)
    rate_limit_rpm   (String)
    log_level        (String)
    feature_dark_mode (String)
    maintenance_mode (String)
  infra/
    s3_uploads_bucket  (String)
    s3_reports_bucket  (String)
    sqs_payment_queue_url (String)
    redis_host         (String)
    redis_port         (String)
    golden_ami_id      (String, data_type=aws:ec2:image)
  shared/
    vpc_id             (String, Advanced)
    private_subnet_ids (StringList, Advanced)
```

---

## Parameter Types — When to Use Each

### String
Use for any non-sensitive plaintext value: hostnames, ports, bucket names, queue URLs, feature flags, log levels.

```hcl
"/prod/fintech-app/database/host" = {
  value = "fintech-prod.cluster-abc123.us-east-1.rds.amazonaws.com"
  type  = "String"
}
```

### SecureString
Use for anything sensitive: passwords, API keys, tokens, JWT secrets, connection strings. Encrypted at rest and in transit using KMS.

```hcl
"/prod/fintech-app/database/password" = {
  value = "my-secret-password"
  type  = "SecureString"
}
```

**Cost note:** SecureString uses your KMS key — each `GetParameter` call with `--with-decryption` incurs a KMS API call ($0.03 per 10,000 calls).

### StringList
Use for comma-separated lists: allowed origins, subnet IDs, CIDR blocks, feature lists.

```hcl
"/prod/fintech-app/app/cors_allowed_origins" = {
  value = "https://app.fintech.com,https://admin.fintech.com"
  type  = "StringList"
}
```

**Note:** StringList cannot be used with `SecureString`. If you need an encrypted list, use a SecureString with your own delimiter convention.

---

## How ECS Reads Parameters at Runtime

ECS natively integrates with SSM via the `secrets` field in your task definition. SSM parameters are injected as environment variables before the container starts.

### Terraform task definition example

```hcl
resource "aws_ecs_task_definition" "api" {
  family                   = "fintech-api"
  execution_role_arn       = aws_iam_role.ecs_execution.arn   # reads SSM
  task_role_arn            = aws_iam_role.ecs_task.arn         # app permissions

  container_definitions = jsonencode([{
    name  = "api"
    image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/fintech-api:latest"

    # SecureString parameters — injected as env vars, never visible in console
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = "/prod/fintech-app/database/password"
      },
      {
        name      = "STRIPE_SECRET_KEY"
        valueFrom = "/prod/fintech-app/stripe/secret_key"
      },
      {
        name      = "JWT_SECRET"
        valueFrom = "/prod/fintech-app/app/jwt_secret"
      }
    ]

    # String parameters — injected as plaintext env vars
    environment = [
      {
        name  = "DB_HOST"
        value = "/prod/fintech-app/database/host"
      },
      {
        name  = "REDIS_HOST"
        value = "/prod/fintech-app/infra/redis_host"
      }
    ]
  }])
}
```

**Important:** The `secrets` array uses `valueFrom` which fetches the value from SSM at container start. The `environment` array injects values literally — you must pass the actual value, not the SSM path (use a `data "aws_ssm_parameter"` lookup for String types if needed).

---

## IAM Policy for ECS Execution Role

The ECS **execution role** (not task role) needs permission to read SSM parameters during container startup.

### Minimal policy (least privilege)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadAppParameters",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParameter",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:us-east-1:123456789012:parameter/prod/fintech-app/*"
    },
    {
      "Sid": "DecryptSecureStrings",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
    }
  ]
}
```

### Terraform

```hcl
resource "aws_iam_role_policy" "ecs_ssm_read" {
  name = "fintech-api-ssm-read"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/fintech-app/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
      }
    ]
  })
}
```

---

## Tier Comparison and Cost

| Feature | Standard | Advanced |
|---|---|---|
| Price | Free for first 10,000; $0.05/10,000 API interactions after | $0.05 per parameter per month |
| Max value size | 4 KB | 8 KB |
| Max parameters | 10,000 per account | 100,000 per account |
| Parameter policies (TTL, expiry) | No | Yes |
| Cross-account sharing via RAM | No | Yes |

**Recommendation:** Use Standard for all parameters unless you need cross-account sharing or TTL-based expiry policies. The fintech app uses Advanced only for the two `shared/` parameters that must be readable from child accounts.

---

## Useful CLI Commands

### Read a plaintext parameter
```bash
aws ssm get-parameter \
  --name "/prod/fintech-app/database/host" \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text
```

### Read a SecureString (decrypted)
```bash
aws ssm get-parameter \
  --name "/prod/fintech-app/database/password" \
  --with-decryption \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text
```

### Read all parameters under a path
```bash
aws ssm get-parameters-by-path \
  --path "/prod/fintech-app/database" \
  --with-decryption \
  --recursive \
  --region us-east-1 \
  --query "Parameters[*].{Name:Name,Value:Value}" \
  --output table
```

### Check parameter history (who changed what and when)
```bash
aws ssm get-parameter-history \
  --name "/prod/fintech-app/stripe/secret_key" \
  --with-decryption \
  --region us-east-1
```

### Update a parameter (new version created, old version retained in history)
```bash
aws ssm put-parameter \
  --name "/prod/fintech-app/database/password" \
  --value "new-rotated-password" \
  --type "SecureString" \
  --key-id "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123" \
  --overwrite \
  --region us-east-1
```

---

## Secret Rotation Pattern

For database passwords, the recommended pattern is:

1. Store initial password in SSM Parameter Store.
2. Create a Lambda function that generates a new password, updates RDS, and calls `ssm:PutParameter` with `--overwrite`.
3. Schedule the Lambda with EventBridge (e.g., every 90 days).
4. ECS tasks pick up the new password on next container restart (blue-green deploy).

Alternatively, use AWS Secrets Manager (which has built-in rotation) and reference the secret ARN in the ECS `secrets` block using `arn:aws:secretsmanager:...` format instead of `arn:aws:ssm:...`.

---

## Prerequisites

- An existing KMS key for SecureString encryption.
- An ECS cluster with a task execution role.
- Replace all placeholder values (`REPLACE_WITH_REAL_KEY`, `123456789012`, `mrk-abc123`) before applying.

```bash
terraform init
terraform plan
terraform apply
```
