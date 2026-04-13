# hr-policy-assistant

Example Bedrock Guardrail for an internal HR self-service assistant.

## Architecture

```mermaid
flowchart LR
    W["Employee request"] --> G["HR policy guardrail"]
    G --> TP["Denied topics<br/>legal advice, investigations,<br/>manager-only payroll actions"]
    G --> CF["Content filters<br/>hate, insults, misconduct,<br/>sexual, prompt attack"]
    G --> PI["Sensitive info policy<br/>employee data anonymization,<br/>SSN and bank blocking"]
    G --> RX["Regex controls<br/>employee IDs and payroll tickets"]
    RX --> M["Bedrock model"]
    M --> O["HR-safe policy response"]
    K["KMS key"] --> G
    G --> V["Published version"]
```

## What This Example Shows

- Workplace-safe topic restrictions
- Protection for employee and payroll data
- Regex coverage for internal HR identifiers
- Guardrail versioning for controlled rollouts

## Run

```bash
terraform init
terraform plan
```
