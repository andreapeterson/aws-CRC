import boto3
import os

table_name = os.environ['table_name']

client = boto3.client('dynamodb')

def lambda_handler(event, context):
    try:
        response = client.get_item(
            TableName=table_name,
            Key={
                'id': {'S': '1'}
            }
        )
        if 'Item' not in response:
            client.put_item(
                TableName=table_name,
                Item={
                    'id': {'S': '1'},
                    'Views': {'N': '1'}
                }
            )
            num_views = 1
        else:
            response = client.update_item(
                TableName=table_name,
                Key={'id': {'S': '1'}},
                ExpressionAttributeNames={'#V': 'Views'},
                ExpressionAttributeValues={':v': {'N': '1'}},
                UpdateExpression='SET #V = #V + :v',
                ReturnValues='ALL_NEW'
            )

            num_views = int(response['Attributes']['Views']['N'])

        return num_views
