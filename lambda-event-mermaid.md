# Lambda Event Architecture - Mermaid Diagram

```mermaid
graph TD
    %% EventBridge Layer
    EB[EventBridge Bus<br/>lambda-event-dev-bus]
    
    %% Rules Layer
    RW[Web Rule<br/>com.miapp.web]
    RA[App Rule<br/>com.miapp.app] 
    RWA[WhatsApp Rule<br/>com.miapp.whatsapp]
    
    %% Lambda Receptoras
    LWR[Lambda Web Receptor]
    LAR[Lambda App Receptor]
    LWAR[Lambda WhatsApp Receptor]
    
    %% SNS Topic
    SNS[SNS Topic<br/>lambda-event-dev-messages]
    
    %% SQS Queues
    SQW[SQS Web Queue<br/>Filter: source=web]
    SQA[SQS App Queue<br/>Filter: source=app]
    SQWA[SQS WhatsApp Queue<br/>Filter: source=whatsapp]
    
    %% Lambda Procesadoras
    LWP[Lambda Web Procesador]
    LAP[Lambda App Procesador]
    LWAP[Lambda WhatsApp Procesador]
    
    %% Connections
    EB --> RW
    EB --> RA
    EB --> RWA
    
    RW --> LWR
    RA --> LAR
    RWA --> LWAR
    
    LWR -->|SNS Publish| SNS
    LAR -->|SNS Publish| SNS
    LWAR -->|SNS Publish| SNS
    
    SNS -->|Subscription Filter| SQW
    SNS -->|Subscription Filter| SQA
    SNS -->|Subscription Filter| SQWA
    
    SQW -->|SQS Trigger| LWP
    SQA -->|SQS Trigger| LAP
    SQWA -->|SQS Trigger| LWAP
    
    %% Styling
    classDef eventbridge fill:#fff2cc,stroke:#d6b656
    classDef lambda fill:#dae8fc,stroke:#6c8ebf
    classDef sns fill:#f8cecc,stroke:#b85450
    classDef sqs fill:#d5e8d4,stroke:#82b366
    classDef rules fill:#e1d5e7,stroke:#9673a6
    
    class EB eventbridge
    class LWR,LAR,LWAR,LWP,LAP,LWAP lambda
    class SNS sns
    class SQW,SQA,SQWA sqs
    class RW,RA,RWA rules
```

## Patrones Implementados:

1. **Publish/Subscribe** (Principal)
2. **Fan-out** (SNS → múltiples SQS)
3. **Event Notification** (eventos livianos)

## Servicios AWS:
- 1 EventBridge Bus
- 3 EventBridge Rules
- 6 Lambda Functions
- 1 SNS Topic
- 3 SQS Queues
- 2 IAM Roles