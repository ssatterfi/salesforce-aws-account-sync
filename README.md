# Salesforce Account → AWS Real-time Sync

Real-time integration that syncs Salesforce Account records to Amazon DynamoDB using API Gateway and Lambda. Includes custom field tracking, error logging, and IAM-secured API access.

## Architecture

 <img width="1168" height="784" alt="image" src="https://github.com/user-attachments/assets/9737431d-c33b-435f-b54a-18f35621abe6" />

# Salesforce Account → AWS Real-time Sync

Real-time integration that syncs Salesforce Account records to Amazon DynamoDB using API Gateway and Lambda. Includes custom field tracking, error logging, and IAM-secured API access.

## Architecture

![Salesforce to AWS Account Sync Architecture](images/architecture.png)

**Flow:**
1. Account is created or updated in Salesforce
2. Apex Trigger enqueues a Queueable job
3. Queueable performs a secure callout using Named Credential (AWS Signature Version 4)
4. API Gateway (IAM authorized) invokes Lambda
5. Lambda writes the record to DynamoDB
6. Salesforce updates `AWS_Sync_Status__c`, `Last_AWS_Sync_Date__c`, and `AWS_Sync_Error_Message__c`

## Features

- Real-time sync on Account create/update
- Custom fields for tracking:
  - `AWS_Sync_Status__c` (Pending / Synced / Failed)
  - `Last_AWS_Sync_Date__c`
  - `AWS_Sync_Error_Message__c`
- Queueable Apex (best practice for callouts)
- Success and failure logging
- **IAM-secured API Gateway** using AWS Signature Version 4
- Fully free-tier compatible (AWS Free Tier + Salesforce Developer Edition)

## Tech Stack

| Layer              | Technology                          |
|--------------------|-------------------------------------|
| CRM                | Salesforce (Apex Trigger + Queueable) |
| Authentication     | Named Credential + External Credential (AWS Signature V4) |
| API                | Amazon API Gateway (HTTP API)       |
| Compute            | AWS Lambda (Python 3.12)            |
| Database           | Amazon DynamoDB                     |

 
 ## Project Structure

```text
salesforce-aws-account-sync/
├── force-app/                        # Salesforce DX source
│   └── main/default/
│       ├── classes/
│       │   ├── AccountAWSSyncHandler.cls
│       │   └── AccountAWSSyncQueueable.cls
│       └── triggers/
│           └── AccountAWSSyncTrigger.trigger
│
├── aws/                              # AWS resources
│   ├── lambda/
│   │   └── salesforce_account_sync.py
│   └── iam/
│       └── dynamodb-policy.json
│
├── images/
│   └── architecture.png
│
└── README.md

## Setup Overview

### Salesforce
- Create custom fields on Account
- Deploy Apex Trigger + Handler + Queueable
- Configure External Credential (AWS Signature Version 4)
- Configure Named Credential
- Assign External Credential Principal to a Permission Set

### AWS
- Create DynamoDB table `SalesforceAccounts` (Partition key: `Id`)
- Create Lambda function and attach DynamoDB permissions
- Create HTTP API in API Gateway with IAM authorization
- Create IAM user with `execute-api:Invoke` permission

## Security

- API Gateway protected with **AWS IAM Authorization**
- Salesforce uses **AWS Signature Version 4** via Named Credential
- Least-privilege IAM policy for Lambda (`dynamodb:PutItem` only)
- No hard-coded credentials in Apex

## Screenshots

> Add your screenshots here

- Salesforce Account record showing **Synced** status
- DynamoDB item
- Lambda / API Gateway CloudWatch logs

## Author

[Scott E Satterfield]

## License

This project is open source and available under the [MIT License](LICENSE).
