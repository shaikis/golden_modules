# CloudFormation Custom Resource — Terraform Escape Hatch

A production-ready Terraform module that lets you manage **any AWS resource** — even those with no native Terraform provider support — by wrapping a Lambda function in a CloudFormation Custom Resource.

---

## When to Use This Pattern

The AWS provider for Terraform lags behind AWS service releases by weeks or months. When you need to automate a brand-new AWS API (e.g. AWS DevOps Agent, new Bedrock features, Managed Grafana advanced config) before `hashicorp/aws` ships a resource, this module gives you a clean, lifecycle-safe escape hatch:

- **No hacks** — no `null_resource` + `local-exec` that breaks on destroy.
- **Full lifecycle** — Create, Update, and Delete are all handled deterministically.
- **Re-trigger on demand** — use `trigger_on_change` to force re-invocation.
- **Outputs** — return data from your Lambda back to Terraform outputs.

---

## How It Works

```
terraform apply / destroy
        |
        v
aws_cloudformation_stack  (Custom Resource wrapper)
        |
        |  CloudFormation sends HTTP POST to Lambda
        |  with RequestType = Create | Update | Delete
        v
aws_lambda_function  (your handler code)
        |
        |  boto3 API calls to AWS service
        v
AWS Service  (DevOps Agent, Grafana, Bedrock, etc.)
        |
        |  Lambda sends SUCCESS / FAILED back to
        |  CloudFormation's pre-signed S3 ResponseURL
        v
CloudFormation marks stack CREATE_COMPLETE / UPDATE_COMPLETE / DELETE_COMPLETE
        |
        v
Terraform sees stack settled -- apply / destroy completes
```

### Lifecycle Detail

| Terraform action          | CloudFormation event | Lambda function called |
|---------------------------|---------------------|------------------------|
| `terraform apply` (first) | `CREATE`            | `_on_create(props)`    |
| `terraform apply` (change)| `UPDATE`            | `_on_update(physical_id, props, old_props)` |
| `terraform destroy`       | `DELETE`            | `_on_delete(physical_id, props)` |

The Lambda **must** send a response to `event["ResponseURL"]` within `var.timeout` seconds, or CloudFormation will time out and roll back.

---

## Quick Start

### Step 1 — Copy the base handler template

```bash
cp lambda_src/base_handler.py my_module/lambda_src/handler.py
```

### Step 2 — Implement the three lifecycle functions

Open `handler.py` and fill in `_on_create`, `_on_update`, and `_on_delete`:

```python
def _on_create(props: dict) -> tuple[str, dict]:
    client = boto3.client("some-aws-service")
    resp = client.create_thing(name=props["ThingName"])
    thing_id = resp["thing"]["id"]
    return thing_id, {"ThingId": thing_id, "ThingArn": resp["thing"]["arn"]}

def _on_delete(physical_id: str, props: dict) -> None:
    client = boto3.client("some-aws-service")
    try:
        client.delete_thing(thingId=physical_id)
    except client.exceptions.ResourceNotFoundException:
        pass  # Already gone -- safe to ignore on destroy
```

### Step 3 — Package the Lambda

```bash
cd my_module/lambda_src
zip handler.zip handler.py
```

If your handler imports third-party packages, bundle them into the zip:

```bash
pip install -r requirements.txt -t .
zip -r handler.zip .
```

### Step 4 — Reference the module

```hcl
module "my_custom_resource" {
  source = "path/to/tf-aws-custom-resource"

  name          = "my-thing"
  environment   = "prod"
  resource_type = "MyThing"

  create_lambda = true
  timeout       = 300

  properties = {
    ThingName = "my-thing-prod"
    Region    = "us-east-1"
  }

  output_attributes = {
    thing_id  = "ThingId"
    thing_arn = "ThingArn"
  }
}

output "thing_id" {
  value = module.my_custom_resource.stack_outputs["thing_id"]
}
```

---

## Full Example — AWS DevOps Agent

The `examples/devops-agent/` directory contains a complete working example. Key snippets:

```hcl
module "devops_agent" {
  source = "../../../tf-aws-custom-resource"

  name          = "${local.prefix}-devops-agent"
  environment   = var.environment
  tags          = var.tags
  resource_type = "DevOpsAgentSpace"

  create_lambda   = true
  lambda_role_arn = module.cr_lambda_role.role_arn
  timeout         = 300

  properties = {
    AgentSpaceName = local.prefix
    EksClusterArn  = var.eks_cluster_arn
    PrometheusArn  = var.prometheus_workspace_arn
    Region         = var.aws_region
  }

  output_attributes = {
    agent_space_id = "AgentSpaceId"
  }

  # Re-trigger whenever the EKS cluster or Prometheus workspace ARN changes
  trigger_on_change = sha256("${var.eks_cluster_arn}${var.prometheus_workspace_arn}")
}

output "agent_space_id" {
  value = module.devops_agent.stack_outputs["agent_space_id"]
}
```

The corresponding Lambda handler is at `lambda_src/examples/devops_agent_handler.py`.

---

## Bring Your Own Lambda

If you already have a Lambda function deployed separately, skip Lambda creation entirely:

```hcl
module "my_custom_resource" {
  source = "path/to/tf-aws-custom-resource"

  name       = "my-thing"
  lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-existing-handler"

  create_lambda = false   # Do not create Lambda -- use the one above

  resource_type = "MyThing"
  properties    = { ThingName = "my-thing" }
}
```

---

## Tips

### trigger_on_change — forced re-invocation

By default, CloudFormation only calls UPDATE when `Properties` in the template change. Use `trigger_on_change` to force a re-run without changing real properties:

```hcl
# Always re-run on every terraform apply:
trigger_on_change = timestamp()

# Re-run only when upstream resources change:
trigger_on_change = sha256("${module.eks.cluster_arn}${module.amp.workspace_arn}")
```

### physical_id — critical for Update and Delete

`_on_create` must return a stable, unique `physical_id`. CloudFormation passes this back on every subsequent `Update` and `Delete` call. If your physical_id changes between Create and Update, CloudFormation treats it as a resource replacement (Delete old + Create new).

Use the resource's primary identifier (e.g. `agentSpaceId`, `workspaceId`) as the physical_id — never a name that could change.

### Testing Lambda locally before deploying

Simulate CloudFormation events locally to verify your handler before deploying:

```python
import json
from unittest.mock import MagicMock
from handler import lambda_handler

event = {
    "RequestType": "Create",
    "ResponseURL": "https://httpbin.org/put",   # Use a test endpoint
    "StackId": "arn:aws:cloudformation:us-east-1:123:stack/test/abc",
    "RequestId": "test-request-id",
    "LogicalResourceId": "CustomResource",
    "ResourceProperties": {
        "ServiceToken": "arn:aws:lambda:...",
        "ThingName": "test-thing",
    },
}
context = MagicMock()
context.log_stream_name = "test-log-stream"

lambda_handler(event, context)
```

### CloudFormation stack rollback on failure

If the Lambda sends `FAILED` (or times out), CloudFormation rolls back the stack. On rollback, CloudFormation sends a `DELETE` event for any resources that were created during that failed stack operation. Ensure your `_on_delete` is idempotent and handles `ResourceNotFoundException` gracefully.

### Lambda timeout vs stack timeout

`var.timeout` (Lambda) must be strictly less than `var.stack_timeout_minutes * 60` (CloudFormation). The recommended gap is at least 30 seconds. Default values (300s Lambda, 30min stack) satisfy this.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name for the custom resource and CloudFormation stack. | `string` | — | yes |
| `name_prefix` | Optional prefix prepended to the name. | `string` | `""` | no |
| `environment` | Deployment environment (dev, staging, prod). | `string` | `"dev"` | no |
| `tags` | Tags applied to Lambda and IAM role. | `map(string)` | `{}` | no |
| `lambda_arn` | ARN of an existing Lambda to use. When set, `create_lambda` must be `false`. | `string` | `null` | no |
| `create_lambda` | Create a Lambda from `lambda_src/handler.zip`. | `bool` | `true` | no |
| `runtime` | Lambda runtime. | `string` | `"python3.12"` | no |
| `memory_size` | Lambda memory in MB. | `number` | `256` | no |
| `timeout` | Lambda timeout in seconds. | `number` | `300` | no |
| `lambda_role_arn` | IAM role ARN for Lambda. Auto-created when null. | `string` | `null` | no |
| `additional_policy_statements` | Extra IAM statements added to the auto-created role. | `list(object)` | `[]` | no |
| `environment_variables` | Lambda environment variables (sensitive). | `map(string)` | `{}` | no |
| `kms_key_arn` | KMS key ARN for encrypting env vars and log group. | `string` | `null` | no |
| `resource_type` | CloudFormation Custom Resource type suffix. Full type = `Custom::<resource_type>`. | `string` | `"CustomResource"` | no |
| `properties` | Properties passed to the Lambda on Create/Update. All values must be strings. | `map(string)` | `{}` | no |
| `output_attributes` | Map of Terraform output name => Lambda response attribute name. | `map(string)` | `{}` | no |
| `stack_timeout_minutes` | CloudFormation stack creation timeout in minutes. | `number` | `30` | no |
| `trigger_on_change` | Forces re-invocation when this value changes. Use `timestamp()` or a hash. | `string` | `""` | no |
| `log_retention_days` | CloudWatch log retention for Lambda logs. | `number` | `14` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `physical_resource_id` | Physical ID returned by the custom resource Lambda. |
| `stack_id` | CloudFormation stack ARN. |
| `stack_outputs` | All CloudFormation stack outputs as a map. Access with `stack_outputs["key"]`. |
| `lambda_arn` | ARN of the custom resource Lambda function. |
| `lambda_role_arn` | ARN of the Lambda IAM execution role. |

---

## Real-World Use Cases

| AWS Service | boto3 API calls | Notes |
|---|---|---|
| **AWS DevOps Agent — Agent Space** | `devops-agent:CreateAgentSpace`, `devops-agent:DeleteAgentSpace`, `devops-agent:AssociateDataSource` | See `lambda_src/examples/devops_agent_handler.py` for a complete implementation. |
| **Amazon Managed Grafana** | `grafana:CreateWorkspace`, `grafana:DeleteWorkspace`, `grafana:AssociateLicense` | Use for advanced workspace config not yet in `aws_grafana_workspace`. |
| **Bedrock AgentCore Runtime** | `bedrock-agentcore:CreateAgentRuntime`, `bedrock-agentcore:DeleteAgentRuntime` | Bridge the gap until `hashicorp/aws` ships native support. |
| **AWS Clean Rooms** | `cleanrooms:CreateCollaboration`, `cleanrooms:DeleteCollaboration` | Manage collaboration memberships that lack Terraform resources. |
| **Any boto3 API call** | Any `boto3.client("service").create_*` / `delete_*` pair | If boto3 supports it and Terraform doesn't yet, this pattern covers it. |

---

## Directory Structure

```
tf-aws-custom-resource/
├── versions.tf                        # Provider constraints
├── variables.tf                       # All input variables
├── main.tf                            # IAM role, Lambda, CloudFormation stack
├── outputs.tf                         # Stack outputs and resource ARNs
├── lambda_src/
│   ├── base_handler.py                # Template -- copy and customise
│   └── examples/
│       └── devops_agent_handler.py    # Complete DevOps Agent example
├── examples/
│   └── devops-agent/
│       ├── main.tf                    # Full usage example
│       └── variables.tf
└── tests/
    └── unit/
        └── defaults.tftest.hcl        # Terraform test assertions
```

---

## Requirements

| Tool | Minimum version |
|------|----------------|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0 |
| Python (for Lambda) | 3.12 (configurable via `var.runtime`) |

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.

