# tf-aws-guardrail Examples

Runnable examples for the [`tf-aws-guardrail`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [customer-support-bot](customer-support-bot/) | E-commerce support chatbot — blocks competitor comparisons, PII anonymization, hate/insults/prompt-attack filters, profanity list |
| [healthcare-assistant](healthcare-assistant/) | Medical Q&A assistant — strict PHI blocking (HIPAA), prescription denial topic, hallucination grounding check, emergency redirects |
| [financial-advisor-bot](financial-advisor-bot/) | Fintech advisor — investment advice denial, competitor product blocking, full PII block (SSN, bank accounts, IBAN), prompt injection defense |

## Architecture

```mermaid
graph TB
    subgraph Examples["Example Scenarios"]
        CS["customer-support-bot\nRetail / E-Commerce"]
        HA["healthcare-assistant\nHospital / Clinical"]
        FA["financial-advisor-bot\nFintech / Regulated"]
    end

    subgraph Guardrail["Bedrock Guardrail (each example)"]
        style Guardrail fill:#FF9900,color:#232F3E
        TP["Topic Policy\n(DENY denied topics)"]
        CF["Content Filters\nHATE / INSULTS\nPROMPT_ATTACK"]
        WF["Word Filters\nPROFANITY + custom"]
        PI["PII / Sensitive Info\nANONYMIZE or BLOCK"]
        GR["Grounding Check\n(healthcare only)"]
    end

    KMS["KMS Key\n(tf-aws-kms module)"]
    MODEL["Bedrock Model\n(Claude)"]
    VER["Guardrail Version\n(immutable snapshot)"]

    CS & HA & FA --> Guardrail
    KMS --> Guardrail
    Guardrail --> VER
    Guardrail --> MODEL
```

## Quick Start

```bash
cd customer-support-bot/
terraform init
terraform apply -var-file="dev.tfvars"
```
