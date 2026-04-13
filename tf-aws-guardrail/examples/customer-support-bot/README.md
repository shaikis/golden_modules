# customer-support-bot

Example Bedrock Guardrail for a public-facing e-commerce support chatbot.

## Architecture

```mermaid
flowchart LR
    U["Customer message"] --> G["Customer support guardrail"]
    G --> TP["Denied topics<br/>competitor comparisons"]
    G --> CF["Content filters<br/>hate, insults, violence,<br/>sexual, misconduct, prompt attack"]
    G --> WP["Word policy<br/>profanity + brand-safe terms"]
    G --> PI["PII controls<br/>anonymize contact data,<br/>block cards and SSNs"]
    PI --> M["Bedrock model"]
    M --> R["Safe support response"]
    K["KMS key"] --> G
    G --> V["Published version"]
```

## What This Example Shows

- Competitor and financial-advice topic denial
- Profanity plus custom word blocking
- Customer PII anonymization and payment-data blocking
- Versioned guardrail protected by a dedicated KMS key

## Run

```bash
terraform init
terraform plan
```
