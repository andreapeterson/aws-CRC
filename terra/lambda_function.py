import boto3
import os

table_name = os.environ['table_name']

client = boto3.client('dynamodb')

count = 0

def lambda_handler(event, context):
    global count
    if count == 0:
        client.put_item(
            TableName=table_name,
            Item={
                'id': {
                    'S': '1'},
                'Views': {
                    'N': '1'}
            })
        count += 1
        return 1
    else:
        response2 = client.update_item(
            TableName=table_name,
            Key={
                'id': {
                    'S': '1'}
            },
            ExpressionAttributeNames={'#V': 'Views'},
            ExpressionAttributeValues={':v': {'N': '1'}},
            UpdateExpression='SET #V = #V + :v',
            ReturnValues='ALL_NEW'
        )

        num_views = response2['Attributes']['Views']['N']

        return num_views
