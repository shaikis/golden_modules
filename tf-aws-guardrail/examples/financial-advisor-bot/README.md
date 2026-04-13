# financial-advisor-bot

Example Bedrock Guardrail for a retail-investing assistant in a regulated environment.

## Architecture

```mermaid
flowchart LR
    I["Investor prompt"] --> G["Financial advisor guardrail"]
    G --> TP["Denied topics<br/>investment advice, tax advice,<br/>competitors, market predictions"]
    G --> CF["Content filters<br/>hate, insults, misconduct,<br/>violence, sexual, prompt attack"]
    G --> WP["Word policy<br/>profanity + fraud terms"]
    G --> PI["Sensitive info policy<br/>SSN, bank, card, IBAN,<br/>SWIFT, PIN blocking"]
    G --> RX["Regex controls<br/>internal account and portfolio IDs"]
    RX --> M["Bedrock model"]
    M --> O["Compliant educational response"]
    K["KMS key"] --> G
    G --> V["Published version"]
```

## What This Example Shows

- SEC/FINRA-style topic restrictions
- Fraud-related custom word filters
- Strict financial identifier blocking
- Internal account pattern protection

## Run

```bash
terraform init
terraform plan
```
