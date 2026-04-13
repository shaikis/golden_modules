# healthcare-assistant

Example Bedrock Guardrail for a healthcare Q&A assistant with strict safety controls.

## Architecture

```mermaid
flowchart LR
    P["Patient question"] --> G["Healthcare guardrail"]
    G --> TP["Denied topics<br/>prescriptions, diagnosis,<br/>self-harm guidance"]
    G --> CF["Content filters<br/>violence, misconduct,<br/>hate, insults, sexual, prompt attack"]
    G --> PI["Sensitive info policy<br/>PHI anonymization + regex rules"]
    G --> CG["Grounding checks<br/>grounding + relevance thresholds"]
    CG --> M["Bedrock model with retrieved docs"]
    M --> O["Clinically safe response"]
    K["KMS key"] --> G
    G --> V["Published version"]
```

## What This Example Shows

- High-risk medical topic denial
- PHI protection with entity rules and custom regex patterns
- Grounding enforcement for RAG-style medical responses
- Emergency-safe blocked messaging

## Run

```bash
terraform init
terraform plan
```
