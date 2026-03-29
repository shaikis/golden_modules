# tf-aws-ses

## Quick Start — minimal setup

```hcl
module "ses" {
  source = "github.com/your-org/tf-aws-ses"

  domain_identities = {
    primary = {
      domain       = "example.com"
      dkim_signing = true
    }
  }
}
```

That's it. One domain, DKIM enabled, nothing else created.

## Feature flags

Enable additional features by setting these variables:

| Flag | Default | What it creates |
|------|---------|-----------------|
| `create_configuration_sets` | `false` | Config sets + event destinations (SNS/CloudWatch/Firehose) |
| `create_receipt_rules` | `false` | Inbound email routing rules |
| `create_templates` | `false` | HTML/text email templates |
| `create_iam_roles` | `false` | IAM roles for SES->Firehose, SES->S3 |

---

Production-grade Terraform module for **Amazon Simple Email Service (SES v2)**.
Covers domain/email identities, DKIM, MAIL FROM, configuration sets with event
destinations (SNS, CloudWatch, Kinesis Firehose, Pinpoint), receipt rule sets,
email templates, and IAM roles — all driven by `for_each` maps with zero
hardcoded regions or account IDs.

---

## Architecture

```
                         ┌─────────────────────────────────────────────────┐
                         │                  AWS SES (v2)                   │
                         │                                                 │
  Sender App ──SendEmail─►  Identity (domain / email address)              │
                         │      │                                          │
                         │      └─► Configuration Set                      │
                         │              │                                  │
                         │    ┌─────────┼──────────────────┐               │
                         │    ▼         ▼                  ▼               │
                         │   SNS    CloudWatch       Kinesis Firehose       │
                         │  Topic    Metrics       (→ S3 / Redshift / ES)  │
                         │                                                 │
  Internet ──InboundMail─►  Receipt Rule Set                               │
                         │      │                                          │
                         │   ┌──┼──────────────┐                           │
                         │   ▼  ▼              ▼                           │
                         │   S3  SNS        Lambda                         │
                         │  (store) (notify) (process)                     │
                         └─────────────────────────────────────────────────┘

  DNS (Route 53 / other):
    <token>._domainkey.<domain>  CNAME  <token>.dkim.amazonses.com   ← DKIM
    mail.<domain>                MX     feedback-smtp.<region>.amazonses.com ← MAIL FROM
    mail.<domain>                TXT    "v=spf1 include:amazonses.com ~all"
```

---

## Features

| Feature | Resource |
|---|---|
| Domain identity | `aws_sesv2_email_identity` |
| Email address identity | `aws_sesv2_email_identity` |
| Easy DKIM (RSA 2048) | `aws_sesv2_email_identity_dkim_signing_attributes` |
| Custom MAIL FROM | `aws_sesv2_email_identity_mail_from_attributes` |
| Legacy DKIM tokens | `aws_ses_domain_dkim` |
| Configuration sets | `aws_sesv2_configuration_set` |
| Event destinations | `aws_sesv2_configuration_set_event_destination` |
| Receipt rule sets | `aws_ses_receipt_rule_set` |
| Active rule set | `aws_ses_active_receipt_rule_set` |
| Receipt rules | `aws_ses_receipt_rule` |
| Email templates | `aws_ses_template` |
| SES → Firehose IAM role | `aws_iam_role` |
| SES → S3 IAM role | `aws_iam_role` |
| Sending policy doc | `aws_iam_policy_document` |

---

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "ses" {
  source = "git::https://github.com/example/tf-aws-ses.git?ref=v1.0.0"

  domain_identities = {
    primary = {
      domain           = "example.com"
      dkim_signing     = true
      mail_from_domain = "mail.example.com"
      configuration_set_name = "transactional"
    }
  }

  configuration_sets = {
    transactional = {
      sending_enabled            = true
      reputation_metrics_enabled = true
      suppression_reasons        = ["BOUNCE", "COMPLAINT"]
      event_destinations = {
        bounces = {
          event_types = ["BOUNCE", "COMPLAINT"]
          sns_destination = {
            topic_arn = aws_sns_topic.bounces.arn
          }
        }
      }
    }
  }

  templates = {
    welcome = {
      subject   = "Welcome, {{first_name}}!"
      html_part = "<h1>Welcome!</h1>"
      text_part = "Welcome!"
    }
  }

  tags = { Environment = "production" }
}
```

---

## DKIM Setup (DNS Records)

After applying, run:

```bash
terraform output -json dkim_cname_records
```

You will get a structure like:

```json
{
  "primary": [
    { "name": "abc123._domainkey.example.com", "value": "abc123.dkim.amazonses.com" },
    { "name": "def456._domainkey.example.com", "value": "def456.dkim.amazonses.com" },
    { "name": "ghi789._domainkey.example.com", "value": "ghi789.dkim.amazonses.com" }
  ]
}
```

Add **all three** CNAME records in your DNS. Verification typically takes 5–15
minutes and up to 72 hours for slow-propagating providers.

### Using Terraform + Route 53

```hcl
locals {
  dkim_records = flatten([
    for domain_key, records in module.ses.dkim_cname_records : records
  ])
}

resource "aws_route53_record" "dkim" {
  for_each = { for r in local.dkim_records : r.name => r }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "CNAME"
  ttl     = 300
  records = [each.value.value]
}
```

---

## MAIL FROM Setup

A custom MAIL FROM domain improves deliverability and lets you pass SPF checks
on your own domain rather than Amazon's.

### DNS records required

```
# MX record — route bounces to SES
mail.example.com.  MX  10  feedback-smtp.us-east-1.amazonses.com.

# SPF record
mail.example.com.  TXT "v=spf1 include:amazonses.com ~all"
```

### Terraform Route 53 example

```hcl
resource "aws_route53_record" "mail_from_mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mail.example.com"
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.${module.ses.aws_region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mail.example.com"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}
```

---

## Bounce and Complaint Handling Flow

```
Email sent → SES tracks delivery
               │
    ┌──────────┼──────────────┐
    ▼          ▼              ▼
  BOUNCE   COMPLAINT      DELIVERY
    │          │
    └────┬─────┘
         ▼
     SNS Topic
    (ses-bounces-complaints)
         │
    ┌────┴────┐
    ▼         ▼
  SQS Q   Lambda fn
(dead-letter) (update DB:
              mark address
              as suppressed)
         │
         ▼
  SES Account-Level
  Suppression List
  (auto via config set
   suppression_reasons)
```

**Best practices:**
1. Always subscribe an SNS → SQS → Lambda pipeline to process bounce/complaint
   notifications within minutes.
2. Store suppressed addresses in your own database — do not re-send to them.
3. Use `suppression_reasons = ["BOUNCE", "COMPLAINT"]` on every configuration
   set to feed the account-level suppression list automatically.
4. Monitor `Reputation.BounceRate` and `Reputation.ComplaintRate` CloudWatch
   metrics. Bounce >5% or complaint >0.1% can trigger sending pause.

---

## Real-World SRE Scenarios

### 1. Transactional Email — High Deliverability

**Goal:** Ensure password resets, invoices, and account notifications reach
inboxes with maximum reliability.

```hcl
configuration_sets = {
  transactional = {
    sending_enabled            = true
    reputation_metrics_enabled = true
    suppression_reasons        = ["BOUNCE", "COMPLAINT"]
    engagement_metrics         = false  # avoid tracking pixels in transactional
    event_destinations = {
      ops_sns = {
        event_types     = ["BOUNCE", "COMPLAINT", "RENDERING_FAILURE"]
        sns_destination = { topic_arn = aws_sns_topic.ops_alerts.arn }
      }
    }
  }
}
```

**SRE practice:** Set CloudWatch alarms on `BounceRate > 0.02` and
`ComplaintRate > 0.001`. Page on-call when triggered.

---

### 2. Marketing Email — Open/Click Tracking with Firehose

**Goal:** Capture engagement events for a data warehouse (Redshift/S3) to
measure campaign ROI.

```hcl
configuration_sets = {
  marketing = {
    engagement_metrics        = true
    optimized_shared_delivery = true
    custom_redirect_domain    = "click.newsletter.example.com"
    event_destinations = {
      firehose = {
        event_types = ["SEND","DELIVERY","OPEN","CLICK","BOUNCE","COMPLAINT"]
        kinesis_firehose_destination = {
          delivery_stream_arn = aws_kinesis_firehose_delivery_stream.events.arn
        }
      }
    }
  }
}
```

**SRE practice:** Partition the Firehose S3 prefix by
`year/month/day/hour` for cost-efficient Athena queries.

---

### 3. Inbound Mail Routing — Support Ticket Ingestion

**Goal:** Receive email at `support@example.com`, store in S3, and trigger a
Lambda that creates a Zendesk ticket.

```hcl
rule_sets = { support-inbound = { active = true } }

receipt_rules = {
  create_ticket = {
    rule_set_name = "support-inbound"
    recipients    = ["support@example.com"]
    s3_actions    = [{ bucket_name = "acme-inbound", key_prefix = "support/", position = 1 }]
    lambda_actions = [{
      function_arn    = aws_lambda_function.zendesk_bridge.arn
      invocation_type = "Event"
      position        = 2
    }]
  }
}
```

---

### 4. Suppression List Management — GDPR / Unsubscribe Compliance

**Goal:** Remove unsubscribed or deleted users from the account-level
suppression list using the SES API.

**Architecture:**
- Users click "Unsubscribe" → API Gateway → Lambda →
  `sesv2:PutSuppressedDestination` (adds to account suppression list)
- Monthly cron Lambda → `sesv2:ListSuppressedDestinations` →
  sync to marketing database

**Terraform (Lambda policy):**

```hcl
data "aws_iam_policy_document" "unsubscribe_lambda" {
  statement {
    actions   = ["ses:PutSuppressedDestination", "ses:ListSuppressedDestinations"]
    resources = ["*"]
  }
}
```

---

### 5. Multi-Domain Sending — Brand Isolation

**Goal:** Send from `example.com` (corporate), `promo.example.com` (deals),
`alerts.example.com` (monitoring) each with separate reputation tracking.

```hcl
domain_identities = {
  corporate  = { domain = "example.com",       configuration_set_name = "corporate" }
  promotions = { domain = "promo.example.com", configuration_set_name = "marketing" }
  alerts     = { domain = "alerts.example.com",configuration_set_name = "alerts" }
}
```

**SRE practice:** Isolate configuration sets so a marketing reputation problem
does not affect transactional or alert delivery.

---

### 6. Rendering Failure Alerting

**Goal:** Get paged immediately if a Handlebars template variable is missing
and an email fails to render.

```hcl
event_destinations = {
  render_fail_sns = {
    event_types     = ["RENDERING_FAILURE"]
    enabled         = true
    sns_destination = { topic_arn = aws_sns_topic.pagerduty.arn }
  }
}
```

**SRE practice:** Treat `RENDERING_FAILURE` like a 5xx error — it means a
customer did not receive their email.

---

### 7. Dedicated IP Warm-Up Monitoring

**Goal:** During dedicated IP warm-up, track daily volume growth against
the warm-up schedule with CloudWatch.

```hcl
event_destinations = {
  volume_cw = {
    event_types = ["SEND"]
    cloudwatch_destination = {
      dimension_configurations = [{
        dimension_name          = "IpPool"
        dimension_value_source  = "MESSAGE_TAG"
        default_dimension_value = "shared"
      }]
    }
  }
}
```

**SRE practice:** Create a CloudWatch dashboard comparing actual send volume
against the recommended warm-up curve. Alert if you ramp faster than the plan.

---

### 8. VPC-Enabled Lambda Inbound Processor

**Goal:** Process inbound email inside a VPC so the Lambda can reach private
RDS/ElastiCache without NAT Gateway exposure.

```hcl
receipt_rules = {
  store_process = {
    rule_set_name  = "inbound"
    recipients     = ["inbound@example.com"]
    s3_actions     = [{ bucket_name = "inbound-store", position = 1 }]
    lambda_actions = [{
      function_arn    = aws_lambda_function.vpc_processor.arn  # VPC-attached Lambda
      invocation_type = "Event"
      position        = 2
    }]
  }
}
```

**SRE practice:** Add an SQS DLQ to the Lambda so failed processing attempts
are retried and never silently dropped.

---

### 9. Bounce Feedback Loop — Auto-Quarantine

**Goal:** Automatically quarantine email addresses that hard-bounce so that
your application database and SES suppression list stay in sync.

**Flow:**

```
SES BOUNCE event
  → SNS topic (ses-bounces)
  → SQS queue
  → Lambda (quarantine-handler)
       ├── UPDATE users SET email_status='bounced' WHERE email=:addr
       └── sesv2:PutSuppressedDestination (add to SES suppression list)
```

**IAM policy snippet (output from this module):**

```hcl
# Attach the module's sending policy to your app role
resource "aws_iam_role_policy" "app_ses" {
  name   = "ses-sending"
  role   = aws_iam_role.app.id
  policy = module.ses.ses_sending_iam_policy_json
}
```

---

### 10. Configuration Drift Detection

**Goal:** Ensure no one manually changes SES configuration sets outside of
Terraform, which can silently break event delivery.

**SRE practice:**
1. Enable AWS Config rule `SES_CONFIGURATION_SET_SENDING_ENABLED` to alert on
   changes.
2. Run `terraform plan` in CI on a schedule (e.g., daily) and alert if drift is
   detected (`plan` exits non-zero when resources differ from state).
3. Use `aws_sesv2_configuration_set` `tags` with `ManagedBy = "terraform"` so
   manual resources stand out in the AWS Console.

---

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `domain_identities` | `map(object)` | `{}` | Domain identities to register in SES |
| `email_identities` | `map(object)` | `{}` | Email address identities |
| `configuration_sets` | `map(object)` | `{}` | Configuration sets + event destinations |
| `rule_sets` | `map(object)` | `{}` | Receipt rule sets |
| `receipt_rules` | `map(object)` | `{}` | Receipt rules |
| `templates` | `map(object)` | `{}` | SES email templates |
| `create_firehose_role` | `bool` | `true` | Auto-create SES→Firehose IAM role |
| `create_s3_role` | `bool` | `true` | Auto-create SES→S3 IAM role |
| `firehose_role_name` | `string` | `"ses-firehose-delivery-role"` | Override Firehose role name |
| `s3_role_name` | `string` | `"ses-s3-inbound-role"` | Override S3 role name |
| `sending_identity_arns` | `list(string)` | `[]` | Extra ARNs for sending policy |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|---|---|
| `domain_identity_arns` | Map of key → domain identity ARN |
| `email_identity_arns` | Map of key → email identity ARN |
| `dkim_tokens` | Map of key → list of DKIM tokens |
| `dkim_cname_records` | Map of key → list of `{name, value}` CNAME objects |
| `mail_from_domains` | Map of key → MAIL FROM domain string |
| `configuration_set_arns` | Map of config set name → ARN |
| `receipt_rule_set_names` | Map of key → rule set name |
| `receipt_rule_arns` | Map of key → receipt rule ARN |
| `template_names` | List of template names |
| `ses_firehose_role_arn` | IAM role ARN for Firehose delivery |
| `ses_s3_role_arn` | IAM role ARN for S3 inbound |
| `ses_sending_iam_policy_json` | JSON policy for application sending |
| `aws_region` | Deployed region |
| `aws_account_id` | Deployed account ID |

---

## Requirements

| Requirement | Version |
|---|---|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0.0 |

---

## License

MIT

