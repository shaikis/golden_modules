# Bedrock Agent + Slack Integration

This solution wires an Amazon Bedrock Agent (Claude Sonnet) into a Slack workspace so that users can mention the bot or DM it and receive AI-generated responses in-thread. It is directly inspired by the AWS blog post *"Build a Slack bot powered by Amazon Bedrock AgentCore"* and implements the same async fan-out architecture described there — but uses native **Bedrock Agents** (serverless, no container runtime required) and **Terraform reusable modules** instead of CDK and the AgentCore Runtime container service.

---

## Architecture

```
                         ┌─────────────────────────────────────────────────────────────┐
                         │                        AWS Account                           │
                         │                                                               │
  Slack Workspace        │  API Gateway (HTTP v2)                                        │
  ┌──────────────┐       │  ┌──────────────────────────────┐                            │
  │  User posts  │──────▶│  │  POST /slack/events          │                            │
  │  message /   │       │  │  GET  /health                │                            │
  │  @mentions   │       │  └──────────────┬───────────────┘                            │
  │  bot         │       │                 │                                             │
  └──────────────┘       │                 ▼                                             │
         ▲               │  Lambda: Verification (timeout=10s, memory=256MB)            │
         │               │  ┌──────────────────────────────────────────────┐            │
         │               │  │ 1. Validate HMAC-SHA256 Slack signature      │            │
         │               │  │ 2. Handle url_verification challenge         │            │
         │               │  │ 3. Return HTTP 200 immediately               │            │
         │               │  │ 4. Async invoke → SQS Integration Lambda     │            │
         │               │  └──────────────────────┬───────────────────────┘            │
         │               │                         │ async (fire-and-forget)             │
         │               │                         ▼                                     │
         │               │  Lambda: SQS Integration (timeout=30s, memory=256MB)         │
         │               │  ┌──────────────────────────────────────────────┐            │
         │               │  │ 1. Filter bot messages (no infinite loops)   │            │
         │               │  │ 2. Post placeholder ":hourglass: Processing" │            │
         │               │  │ 3. SendMessage → SQS FIFO queue              │            │
         │               │  └──────────────────────┬───────────────────────┘            │
         │               │                         │                                     │
         │               │              ┌──────────▼──────────┐                         │
         │               │              │  SQS FIFO Queue      │                         │
         │               │              │  (+ DLQ, KMS)        │                         │
         │               │              └──────────┬───────────┘                         │
         │               │                         │ event source mapping                │
         │               │                         ▼                                     │
         │               │  Lambda: Agent Integration (timeout=300s, memory=512MB)      │
         │               │  ┌──────────────────────────────────────────────┐            │
         │               │  │ 1. Invoke Bedrock Agent (thread_ts=sessionId)│            │
         │               │  │ 2. Stream + assemble response chunks         │            │
         │               │  │ 3. chat.update placeholder → real answer     │            │
         │               │  │ 4. On error: update placeholder with :x:     │            │
         │               │  └──────────────────────┬───────────────────────┘            │
         │               │                         │                                     │
         │  chat.update  │           ┌─────────────▼──────────────────────┐             │
         └───────────────│───────────│  Bedrock Agent (Claude Sonnet)      │             │
                         │           │  ┌───────────────────────────────┐  │             │
                         │           │  │ Guardrails (PII + hate/       │  │             │
                         │           │  │ violence/prompt-attack)       │  │             │
                         │           │  └───────────────────────────────┘  │             │
                         │           │  ┌───────────────────────────────┐  │             │
                         │           │  │ Invocation Logging → S3       │  │             │
                         │           │  └───────────────────────────────┘  │             │
                         │           └────────────────────────────────────┘             │
                         │                                                               │
                         │  Supporting Infrastructure                                    │
                         │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
                         │  │  ECR Repo    │  │  CodeBuild   │  │  Secrets Manager  │   │
                         │  │  (ARM64      │  │  (ARM64      │  │  (bot_token +     │   │
                         │  │  container)  │  │  image build)│  │  signing_secret)  │   │
                         │  └──────────────┘  └──────────────┘  └──────────────────┘   │
                         │  ┌──────────────┐  ┌──────────────┐                         │
                         │  │  KMS CMK     │  │  SNS Alerts  │                         │
                         │  │  (all-encr.) │  │  (CloudWatch │                         │
                         │  └──────────────┘  │   alarms)    │                         │
                         │                    └──────────────┘                         │
                         └─────────────────────────────────────────────────────────────┘
```

---

## Mermaid Flowchart

```mermaid
flowchart TD
    User["Slack User\n@mention or DM"] -->|"POST /slack/events"| APIGW["API Gateway\nHTTP API v2"]
    APIGW --> LV["Lambda: Verification\ntimeout=10s"]
    LV -->|"HTTP 200 (immediate)"| APIGW
    LV -->|"Async invoke"| LSQS["Lambda: SQS Integration\ntimeout=30s"]
    LSQS -->|"bot filter check"| BotCheck{"Is bot\nmessage?"}
    BotCheck -->|"yes — skip"| Done["Return 200"]
    BotCheck -->|"no"| Placeholder["Post placeholder msg\n:hourglass: Processing..."]
    Placeholder --> SQSEnqueue["SQS FIFO\nMessageGroupId = channel-thread_ts"]
    SQSEnqueue --> LAGENT["Lambda: Agent Integration\ntimeout=300s\n(SQS trigger, batch=1)"]
    LAGENT --> BA["Bedrock Agent\nClaude Sonnet"]
    BA --> GR["Guardrail\nPII + content filters"]
    BA --> LOG["Invocation Logs\nS3 bucket"]
    BA -->|"streamed response"| LAGENT
    LAGENT -->|"chat.update"| SlackUpdate["Slack Thread\n(placeholder → answer)"]
    LAGENT -->|"on failure"| DLQ["SQS DLQ\n(after 3 retries)"]

    SM["Secrets Manager\nbot_token + signing_secret"] -.->|"GetSecretValue"| LV
    SM -.->|"GetSecretValue"| LSQS
    SM -.->|"GetSecretValue"| LAGENT
    KMS["KMS CMK"] -.->|"encrypt"| SM
    KMS -.->|"encrypt"| SQSEnqueue
    KMS -.->|"encrypt"| LOG
    SNS["SNS + Email"] -.->|"alarms"| CW["CloudWatch\nAlarms + Dashboard"]
    LAGENT -.-> CW
```

---

## How It Works

### Solving the Slack 3-Second Timeout

Slack requires your webhook endpoint to respond within **3 seconds** or it will retry the event (causing duplicate processing). Bedrock Agent invocations can take 30–120+ seconds. The solution solves this with a two-stage async pattern:

1. **Verification Lambda** responds `HTTP 200` immediately after validating the HMAC-SHA256 signature, then fires an **asynchronous** (`InvocationType=Event`) invocation to the SQS Integration Lambda — no waiting.
2. The async chain continues through SQS into the Agent Lambda, which can run for up to 300 seconds without the user ever seeing a timeout.

### Conversation Memory via Thread TS (No Database Required)

Each Slack thread has a unique `thread_ts` timestamp. The Agent Integration Lambda uses `thread_ts` (combined with `user_id`) as the Bedrock Agent **session ID**. Bedrock Agents maintain conversation context within a session for `idle_session_ttl_in_seconds` (default 600s / 10 min), so follow-up questions within the same thread get full conversation history — with zero infrastructure overhead.

### Placeholder Message Pattern

Rather than making the user wait in silence, the SQS Integration Lambda immediately posts a `:hourglass_flowing_sand: Processing your request...` message in the thread. When the agent finishes, the Agent Integration Lambda calls `chat.update` to replace that placeholder with the real answer. This gives instant visual feedback.

### Guardrail on Every Invocation

When `enable_bedrock_guardrail = true`, every `invoke_agent` call includes a `guardrailConfiguration` block referencing the guardrail created by the `tf-aws-bedrock` module. The guardrail blocks hate speech, high-severity violence, prompt injection attacks, and PII (SSN, credit cards, AWS keys are blocked; emails and phone numbers are anonymized).

---

## Blog vs This Solution

| Dimension | AWS Blog (AgentCore) | This Terraform Solution |
|-----------|----------------------|-------------------------|
| **Agent runtime** | AgentCore Runtime (container on Fargate/ECS) | Bedrock Agents (fully serverless) |
| **IaC toolchain** | AWS CDK (Python) | Terraform reusable modules |
| **Memory / sessions** | AgentCore Memory (external store) | Bedrock Agent session management (built-in, no DB) |
| **Tool integrations** | AgentCore Gateway + MCP servers | Add `aws_bedrock_agent_agent_action_group` resources to the agent |
| **Architecture pattern** | API GW → Lambda → SQS → Agent Lambda → Bedrock | Identical async fan-out pattern |
| **Container image** | Required for AgentCore Runtime | Optional — ECR + CodeBuild included for custom extensions |
| **Encryption** | Account defaults | Customer-managed KMS key across all services |
| **Observability** | CloudWatch (manual) | CloudWatch alarms + dashboard (module-managed) |

---

## Modules Used

| Module | Purpose |
|--------|---------|
| `tf-aws-kms` | Customer-managed KMS key for encryption at rest |
| `tf-aws-secretsmanager` | Stores Slack Bot Token and Signing Secret |
| `tf-aws-ecr` | ECR repository for agent container image |
| `tf-aws-s3` | Artifacts bucket + Bedrock invocation log storage |
| `tf-aws-codebuild` | ARM64 container image build pipeline |
| `tf-aws-iam-role` | Lambda execution IAM role with least-privilege policies |
| `tf-aws-sqs` | FIFO queue with DLQ for reliable message delivery |
| `tf-aws-sns` | Email alarm notifications for CloudWatch alerts |
| `tf-aws-lambda` | Three Lambda functions (verification, SQS, agent) |
| `tf-aws-apigateway` | HTTP API v2 with Slack event and health routes |
| `tf-aws-bedrock` | Guardrails configuration + model invocation logging |

---

## Prerequisites

### Slack App Setup

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps) and click **Create New App** > **From scratch**.
2. Give it a name (e.g., `bedrock-agent`) and select your workspace.
3. Under **OAuth & Permissions** > **Bot Token Scopes**, add:
   - `app_mentions:read` — receive `@mention` events
   - `chat:write` — post and update messages
   - `im:history` — read DM history
   - `im:read` — access DM channel info
   - `im:write` — open DM conversations
4. Under **Event Subscriptions**, enable events and subscribe to **Bot Events**:
   - `app_mention` — triggered when someone mentions `@yourbot`
   - `message.im` — triggered for direct messages to the bot
5. Under **Basic Information**, copy the **Signing Secret**.
6. Under **OAuth & Permissions**, click **Install to Workspace**, authorize, then copy the **Bot User OAuth Token** (`xoxb-...`).

> The **Request URL** for Event Subscriptions is set *after* `terraform apply` — use the `slack_webhook_url` output.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for all resources | `string` | — | yes |
| `environment` | Deployment environment (dev, staging, prod) | `string` | `"dev"` | no |
| `aws_region` | AWS region to deploy into | `string` | `"us-east-1"` | no |
| `tags` | Additional tags applied to all resources | `map(string)` | `{}` | no |
| `slack_bot_token` | Slack Bot User OAuth Token (`xoxb-...`) | `string` | — | yes |
| `slack_signing_secret` | Slack App Signing Secret | `string` | — | yes |
| `claude_model_id` | Bedrock foundation model ID | `string` | `"anthropic.claude-3-sonnet-20240229-v1:0"` | no |
| `agent_instruction` | System instruction for the Bedrock Agent | `string` | (helpful assistant prompt) | no |
| `enable_bedrock_guardrail` | Enable Bedrock guardrail for PII + content safety | `bool` | `true` | no |
| `enable_bedrock_logging` | Enable Bedrock model invocation logging | `bool` | `true` | no |
| `lambda_memory_mb` | Agent Lambda memory in MB | `number` | `512` | no |
| `lambda_timeout_sec` | Agent Lambda timeout in seconds | `number` | `300` | no |
| `sqs_visibility_timeout` | SQS visibility timeout in seconds (>= lambda_timeout_sec) | `number` | `360` | no |
| `sqs_max_receive_count` | Max SQS receive attempts before DLQ | `number` | `3` | no |
| `agent_image_tag` | ECR image tag for the agent container | `string` | `"latest"` | no |
| `enable_kms_encryption` | Encrypt all resources with a CMK | `bool` | `true` | no |
| `alarm_email` | Email for CloudWatch alarm notifications | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `slack_webhook_url` | **Paste this into Slack App > Event Subscriptions > Request URL** |
| `api_gateway_invoke_url` | Base invocation URL of the HTTP API |
| `api_gateway_id` | API Gateway ID |
| `lambda_verification_name` | Slack verification Lambda function name |
| `lambda_sqs_integration_name` | SQS integration Lambda function name |
| `lambda_agent_integration_name` | Agent integration Lambda function name |
| `lambda_agent_dashboard_url` | CloudWatch dashboard URL for the agent Lambda |
| `sqs_queue_url` | URL of the SQS FIFO queue |
| `sqs_dlq_url` | URL of the Dead Letter Queue |
| `slack_secret_arn` | ARN of the Secrets Manager secret |
| `ecr_repository_url` | ECR repository URL for the agent container image |
| `codebuild_project_name` | CodeBuild project name |
| `bedrock_agent_id` | Bedrock Agent ID |
| `bedrock_agent_alias_id` | Bedrock Agent Alias ID |
| `bedrock_guardrail_id` | Bedrock guardrail ID |
| `bedrock_invocation_log_prefix` | S3 URI for Bedrock invocation logs |
| `lambda_role_arn` | ARN of the Lambda execution IAM role |
| `kms_key_arn` | ARN of the KMS customer-managed key |

---

## Deploying

### Step 1 — Create Slack App

Follow the [Prerequisites](#prerequisites) section above to create the app and collect:
- `Bot User OAuth Token` (`xoxb-...`)
- `Signing Secret`

### Step 2 — Package Lambda Functions

```bash
bash lambda_src/build.sh
```

This creates three zip files in `lambda_src/`:
- `verification.zip`
- `sqs_integration.zip`
- `agent_integration.zip`

### Step 3 — Terraform Apply

```bash
terraform init

terraform apply \
  -var="name=mybot" \
  -var="environment=prod" \
  -var="slack_bot_token=xoxb-YOUR-BOT-TOKEN" \
  -var="slack_signing_secret=YOUR-SIGNING-SECRET" \
  -var="alarm_email=ops@example.com"
```

Alternatively, create a `terraform.tfvars` file:

```hcl
name                 = "mybot"
environment          = "prod"
slack_bot_token      = "xoxb-..."
slack_signing_secret = "abc123..."
alarm_email          = "ops@example.com"
```

### Step 4 — Configure Slack Event Subscriptions

After `terraform apply` completes, copy the `slack_webhook_url` output:

```
Outputs:
  slack_webhook_url = "https://abc123.execute-api.us-east-1.amazonaws.com/v1/slack/events"
```

1. Go to your Slack App > **Event Subscriptions**.
2. Toggle **Enable Events** to ON.
3. Paste the URL into **Request URL** — Slack will send a `url_verification` challenge, which the Verification Lambda handles automatically. You should see a green checkmark.
4. Under **Subscribe to bot events**, confirm `app_mention` and `message.im` are listed.
5. Click **Save Changes**.

### Step 5 — Install App and Test

1. Under **OAuth & Permissions**, click **Install to Workspace** (or **Reinstall** if already installed).
2. Invite the bot to a channel: `/invite @yourbot`
3. Mention the bot: `@yourbot what is the capital of France?`

You should see the placeholder message appear immediately, followed by the real answer within a few seconds.

---

## Testing

### Health Check

```bash
# Replace with your actual invoke URL from the api_gateway_invoke_url output
curl -s https://abc123.execute-api.us-east-1.amazonaws.com/v1/health | jq .
# Expected: {"status": "ok"}
```

### Simulate a Slack Event (requires valid signature)

For integration testing with a real Slack signature, use the Slack CLI or the [Slack Events API tester](https://api.slack.com/events) in your app dashboard.

### Check Lambda Logs

```bash
aws logs tail /aws/lambda/mybot-prod-slack-agent-integration --follow
```

### Monitor DLQ

```bash
# Check DLQ message count — any messages here indicate failed agent invocations
aws sqs get-queue-attributes \
  --queue-url "$(terraform output -raw sqs_dlq_url)" \
  --attribute-names ApproximateNumberOfMessages
```

### CloudWatch Dashboard

Open the URL from the `lambda_agent_dashboard_url` output to see invocation metrics, errors, duration, and throttles for the agent Lambda in one place.
