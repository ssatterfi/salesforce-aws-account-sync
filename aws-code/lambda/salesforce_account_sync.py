import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SalesforceAccounts')

def lambda_handler(event, context):
    try:
        # Handle both API Gateway formats
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
        elif body is None:
            body = {}

        item = {
            'Id': body.get('Id', ''),
            'Name': body.get('Name', ''),
            'Industry': body.get('Industry', ''),
            'Phone': body.get('Phone', ''),
            'Website': body.get('Website', ''),
            'BillingCity': body.get('BillingCity', ''),
            'AWS_Sync_Status__c': body.get('AWS_Sync_Status__c', ''),
            'LastSynced': datetime.utcnow().isoformat() + 'Z'
        }

        table.put_item(Item=item)

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Account synced successfully'})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }