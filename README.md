# Salesforce AWS Account Sync

Real-time Salesforce Account synchronization to AWS (API Gateway, Lambda, and DynamoDB) with custom sync status tracking. This repository uses the Salesforce DX source format.

## Project structure

Salesforce metadata is in `force-app/main/default`:

- `classes/AccountAWSSyncHandler.cls` prepares Account data for synchronization.
- `classes/AccountAWSSyncQueueable.cls` sends Account data to AWS asynchronously.
- `triggers/AccountAWSSyncTrigger.trigger` starts a sync after Account insert or sync-relevant update.
- `objects/Account/fields` defines the sync status and last-sync date fields.

## Deploy

Install the Salesforce CLI (`sf`), authenticate to a Salesforce org, then deploy the source:

```sh
sf org login web --alias my-org --instance-url https://login.salesforce.com
sf project deploy start --source-dir force-app --target-org my-org
```

Use `https://test.salesforce.com` for a sandbox login.

## Configure AWS callout

Before syncing Accounts, configure a Salesforce Named Credential with the API name `AWS_Account_Sync` and a URL for the AWS API Gateway endpoint that accepts the handler's POST request. Configure its authentication to match the AWS endpoint. The Apex handler references this Named Credential as `callout:AWS_Account_Sync`.

The handler queues a callout-capable Queueable job, which also works when Account changes originate in batch or other asynchronous processing. Updates made by the sync itself to `AWS_Sync_Status__c` and `Last_AWS_Sync_Date__c` do not start another sync; changes to the Account data sent to AWS do. The `AWS_Sync_Status__c` field supports `Pending`, `Synced`, and `Failed`. Successful responses also update `Last_AWS_Sync_Date__c`.
