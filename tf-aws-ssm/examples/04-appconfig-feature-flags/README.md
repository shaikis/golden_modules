# Example 4: AppConfig Feature Flags for SaaS Microservices

## Scenario

A SaaS company uses AWS AppConfig to manage feature flags across three environments (dev, staging, prod). New features roll out gradually using a LINEAR deployment strategy — 10% of traffic at a time over 30 minutes. If a CloudWatch alarm fires during rollout (error rate spike, latency increase), AppConfig automatically rolls back to the previous version. No redeployments. No code changes. Just a flag toggle.

Relevant to the Innovation Sandbox on AWS pattern:
> https://aws.amazon.com/blogs/mt/innovation-sandbox-on-aws-with-real-time-analytics-dashboard/

---

## Why AppConfig Over Parameter Store for Feature Flags

| Capability | SSM Parameter Store | AWS AppConfig |
|---|---|---|
| Gradual rollout | No | Yes — LINEAR, EXPONENTIAL |
| Auto-rollback on alarm | No | Yes — CloudWatch integration |
| Deployment bake time | No | Yes — monitor at 100% before completing |
| Config versioning | Basic (version number) | Full version history with compare |
| JSON Schema validation | No | Yes — validates before deployment |
| Native feature flag UI | No | Yes — AWS Console toggle UI |
| Environment promotion | Manual | Built-in dev → staging → prod |
| Config change history | CloudTrail only | Full AppConfig deployment history |
| Cost | Free (first 10K params) | Free (no extra charge) |

**Rule of thumb:** Use Parameter Store for infrastructure references and secrets. Use AppConfig when you need gradual rollout, validation, or rollback capability.

---

## Deployment Strategy: Gradual LINEAR Rollout

The `gradual-prod-rollout` strategy deploys configuration changes in 10% increments over 30 minutes, then holds at 100% for a 10-minute bake time before marking the deployment complete.

```
Time (minutes)  Traffic receiving new config
0               0%  ← deployment starts
3               10%
6               20%
9               30%
12              40%
15              50%
18              60%
21              70%
24              80%
27              90%
30              100%  ← bake time starts
40              100%  ← deployment COMPLETE (if no alarm fired)
```

**If a CloudWatch alarm fires at any point during deployment or bake time:**
AppConfig immediately reverts all traffic back to the previous configuration version. The alarm is polled every 10 seconds during deployment.

**Growth types:**
- `LINEAR` — equal increments (10%, 10%, 10%, ...) — recommended for most cases.
- `EXPONENTIAL` — doubling increments (1%, 2%, 4%, 8%, ...) — for very conservative prod rollouts.

---

## Auto-Rollback via CloudWatch Alarm

The `prod` environment is linked to a CloudWatch alarm. If this alarm goes to `ALARM` state during a deployment, AppConfig rolls back automatically.

```hcl
monitors = [
  {
    alarm_arn      = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:mysaas-prod-api-error-rate"
    alarm_role_arn = "arn:aws:iam::123456789012:role/AppConfigCloudWatchRole"
  }
]
```

### Recommended alarms to link

- **API error rate** — `AWS/ApiGateway 5XXError > 1%` for 2 datapoints in 2 minutes.
- **Lambda error rate** — `AWS/Lambda Errors > 5` for 1 datapoint in 5 minutes.
- **ECS task CPU** — spike may indicate a misconfiguration causing infinite loops.
- **RDS connections** — a bad config change may cause connection storms.

### IAM role for CloudWatch monitoring

AppConfig needs a role to read alarm state:

```hcl
resource "aws_iam_role" "appconfig_cloudwatch" {
  name = "AppConfigCloudWatchRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "appconfig.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "appconfig_cloudwatch" {
  role = aws_iam_role.appconfig_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:DescribeAlarms"]
      Resource = "*"
    }]
  })
}
```

---

## Reading Feature Flags in Your Application

AppConfig provides a local agent (Lambda extension or ECS sidecar) that caches configuration and polls for updates. This avoids an API call on every request.

### Python (Lambda — using AppConfig Lambda extension)

Add the AppConfig Lambda extension layer to your function:
- `arn:aws:lambda:us-east-1:027255383542:layer:AWS-AppConfig-Extension:128`

Then read config from the local extension HTTP server (no SDK call, instant):

```python
import urllib.request
import json

def get_feature_flags():
    """Reads feature flags from AppConfig Lambda extension (cached locally)."""
    url = (
        "http://localhost:2772/applications/mysaas-platform"
        "/environments/prod"
        "/configurations/feature-flags"
    )
    with urllib.request.urlopen(url) as response:
        config = json.loads(response.read())
    return config

def handler(event, context):
    flags = get_feature_flags()

    if flags.get("values", {}).get("new_dashboard", {}).get("enabled"):
        return render_new_dashboard(event)
    else:
        return render_legacy_dashboard(event)
```

The extension automatically polls AppConfig every 45 seconds (configurable). Your function always reads from the local cache — no latency added to the hot path.

### Python (ECS / EC2 — using boto3 direct call)

```python
import boto3
import json
import os

client = boto3.client("appconfigdata", region_name="us-east-1")

# Start a configuration session (do this once at startup, cache the token)
session = client.start_configuration_session(
    ApplicationIdentifier=os.environ["APPCONFIG_APP_ID"],
    EnvironmentIdentifier=os.environ["APPCONFIG_ENV_ID"],
    ConfigurationProfileIdentifier=os.environ["APPCONFIG_PROFILE_ID"],
    RequiredMinimumPollIntervalInSeconds=30
)
token = session["InitialConfigurationToken"]

def get_latest_flags():
    global token
    response = client.get_latest_configuration(ConfigurationToken=token)
    token = response["NextPollConfigurationToken"]  # Always update the token
    if response["Configuration"].read():  # Only non-empty if config changed
        return json.loads(response["Configuration"].read())
    return None  # None means config unchanged — use cached value
```

### Node.js (Lambda — using AppConfig extension)

```javascript
const http = require("http");

async function getFeatureFlags() {
  return new Promise((resolve, reject) => {
    http.get(
      "http://localhost:2772/applications/mysaas-platform/environments/prod/configurations/feature-flags",
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => resolve(JSON.parse(data)));
      }
    ).on("error", reject);
  });
}

exports.handler = async (event) => {
  const flags = await getFeatureFlags();
  const aiEnabled = flags?.values?.ai_suggestions?.enabled ?? false;

  return {
    statusCode: 200,
    body: JSON.stringify({ ai_suggestions_active: aiEnabled }),
  };
};
```

---

## Innovation Sandbox Use Case

The `sandbox-config` profile controls which AWS services each hackathon or innovation team can provision, and sets budget ceilings. This matches the pattern described in the Innovation Sandbox on AWS blog:

```json
{
  "default_budget_usd": 500,
  "allowed_services": [
    "ec2", "s3", "lambda", "dynamodb", "sqs", "sns",
    "apigateway", "cloudwatch", "iam"
  ],
  "auto_terminate_after_days": 30,
  "notify_at_percent": 80
}
```

When a team reaches 80% of their $500 budget, an EventBridge rule triggers a Lambda that reads this config from AppConfig and sends a Slack notification. At 100%, all IAM permissions for that sandbox account are revoked via SCP.

To update the budget for one team without touching the others, you update the hosted configuration and trigger a new deployment — no Terraform changes, no PR review cycle.

---

## Deploying and Creating Hosted Configurations

### 1. Deploy the Terraform

```bash
terraform init
terraform apply
```

### 2. Create a hosted configuration version via Console

1. Open **AWS AppConfig** in the console.
2. Select **mysaas-platform** application.
3. Select **feature-flags** configuration profile.
4. Click **Create hosted configuration version**.
5. Toggle flags using the native feature flag UI.
6. Click **Save version**.

### 3. Deploy the configuration to prod

```bash
aws appconfig start-deployment \
  --application-id $(terraform output -raw appconfig_application_id) \
  --environment-id $(terraform output -json appconfig_environment_ids | jq -r '.prod') \
  --configuration-profile-id $(terraform output -json appconfig_profile_ids | jq -r '."feature-flags"') \
  --configuration-version 1 \
  --deployment-strategy-id $(terraform output -raw appconfig_deployment_strategy_id) \
  --description "Enable new dashboard for all prod users" \
  --region us-east-1
```

### 4. Monitor the deployment

```bash
aws appconfig get-deployment \
  --application-id <app-id> \
  --environment-id <env-id> \
  --deployment-number 1 \
  --region us-east-1 \
  --query "{State:State,PercentComplete:PercentageComplete,EventLog:EventLog[-3:]}"
```

### 5. Roll back manually if needed

```bash
aws appconfig stop-deployment \
  --application-id <app-id> \
  --environment-id <env-id> \
  --deployment-number 1 \
  --region us-east-1
```

---

## Cost

AWS AppConfig has no additional service charge. You pay only for:
- API calls (same rate as standard AWS API calls — effectively free at typical usage).
- The AppConfig Lambda extension layer adds ~5ms to cold start (negligible).

For comparison, Parameter Store Standard is also free. The reason to choose AppConfig is not cost but capability: validation, versioning, gradual rollout, and auto-rollback.

---

## Prerequisites

- Replace `123456789012` with your AWS account ID.
- Create a CloudWatch alarm for API error rate before applying (or remove the `monitors` block for initial setup).
- Create the `AppConfigCloudWatchRole` IAM role (Terraform snippet in the auto-rollback section above).

```bash
terraform init
terraform plan
terraform apply
```
