# Salesforce Account → AWS Real-time Sync

Real-time integration that syncs Salesforce Account records to Amazon DynamoDB using API Gateway and Lambda. Includes custom field tracking, error logging, and IAM-secured API access.

## Architecture

```mermaid
flowchart LR
    A[Salesforce Account] -->|After Insert / Update| B[Apex Trigger]
    B --> C[Queueable Apex]
    C -->|HTTP Callout<br/>Named Credential| D[Amazon API Gateway]
    D -->|IAM Auth| E[AWS Lambda]
    E --> F[(Amazon DynamoDB)]
    C -->|Update Status| A

    style A fill:#00A1E0,stroke:#333,color:#fff
    style D fill:#FF9900,stroke:#333,color:#fff
    style E fill:#FF9900,stroke:#333,color:#fff
    style F fill:#3F8624,stroke:#333,color:#fff
