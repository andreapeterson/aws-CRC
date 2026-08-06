import boto3
import os

table_name = os.environ['table_name']
client = boto3.client('dynamodb')


def lambda_handler(event, context):
    response = client.update_item(
        TableName=table_name,
        Key={'id': {'S': '1'}},
        ExpressionAttributeNames={'#views': 'Views'},
        ExpressionAttributeValues={':increment': {'N': '1'}},
        UpdateExpression='ADD #views :increment',
        ReturnValues='ALL_NEW'
    )

    return int(response['Attributes']['Views']['N'])
