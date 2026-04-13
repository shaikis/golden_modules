# enterprise-rag-assistant

Example Bedrock Guardrail for an internal RAG assistant serving company knowledge.

## Architecture

```mermaid
flowchart LR
    E["Employee query"] --> G["Enterprise RAG guardrail"]
    G --> TP["Denied topics<br/>security bypass and<br/>secret extraction"]
    G --> CF["Content filters<br/>hate, insults, misconduct,<br/>violence, prompt attack"]
    G --> WP["Word policy<br/>prompt-leak phrases"]
    G --> PI["Sensitive info policy<br/>email, names, passwords,<br/>AWS keys, URLs"]
    G --> RX["Regex controls<br/>case IDs and webhook secrets"]
    G --> CG["Grounding checks<br/>internal knowledge responses"]
    CG --> M["Bedrock model + retrieved internal docs"]
    M --> O["Grounded internal answer"]
    K["KMS key"] --> G
    G --> V["Published version"]
```

## What This Example Shows

- Prompt-injection and secret-extraction defense
- Redaction/blocking of sensitive enterprise data
- Regex handling for internal IDs and leaked webhooks
- Strong grounding thresholds for internal RAG

## Run

```bash
terraform init
terraform plan
```
