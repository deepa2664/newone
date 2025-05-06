import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('FileData')  # DynamoDB table name

def lambda_handler(event, context):
    # Extract information from the S3 event
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
        event_time = record['eventTime']
        
        # Prepare item for DynamoDB
        item = {
            'FileID': object_key,  # Use object key as the primary key
            'Timestamp': event_time,
            'Bucket': bucket_name,
            'FileName': object_key.split('/')[-1],  # Extract file name
        }
        
        # Insert the item into DynamoDB
        table.put_item(Item=item)
        print(f"Uploaded {object_key} to DynamoDB")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }
