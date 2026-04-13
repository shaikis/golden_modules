# basic

Minimal deployment of the FSx for ONTAP DR control plane.

## Architecture

```mermaid
graph TB
    OPS["Operator / automation"] --> SFN["Step Functions state machine"]
    SFN --> LMB["Lambda controller"]
    LMB --> SEC["Secrets Manager"]
    LMB --> PRI["Primary ONTAP management endpoint"]
    LMB --> DR["DR ONTAP management endpoint"]
    LMB --> R53["Route 53 DNS record"]
    LMB --> DDB["DynamoDB state table"]
    LMB --> SNS["SNS notifications"]
```

## Scenario Flows

### Switchover

```mermaid
flowchart LR
    A["Planned switchover"] --> B["Check primary and DR reachability"]
    B --> C["Inspect SnapMirror + DR volume"]
    C --> D["Do not break relationship"]
    D --> E["Optional DNS cutover"]
    E --> F["Store reversible state"]
```

### Revert Switchover

```mermaid
flowchart LR
    A["Revert switchover"] --> B["Check primary health"]
    B --> C["Restore DNS to primary"]
    C --> D["Record primary active"]
```

### Failover

```mermaid
flowchart LR
    A["Emergency failover"] --> B["Primary unavailable"]
    B --> C["Break SnapMirror on DR"]
    C --> D["Verify DR volume and junction path"]
    D --> E["Cut DNS to DR"]
```

### Failback

```mermaid
flowchart LR
    A["Region recovered"] --> B["Resync to primary"]
    B --> C["Validate primary volume"]
    C --> D["Restore DNS to primary"]
```

## Outputs to Review

- `switchover_execution_example`
- `revert_switchover_execution_example`
- `failover_execution_example`
- `failback_execution_example`
