import importlib
import os
import sys
import types
import unittest
from unittest.mock import Mock


class LambdaFunctionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.environ['table_name'] = 'test-counter'
        cls.dynamodb = Mock()
        sys.modules['boto3'] = types.SimpleNamespace(
            client=lambda service: cls.dynamodb
        )
        cls.module = importlib.import_module('lambda_function')

    def setUp(self):
        self.dynamodb.reset_mock()

    def test_atomically_increments_and_returns_the_new_count(self):
        self.dynamodb.update_item.return_value = {
            'Attributes': {'Views': {'N': '42'}}
        }

        result = self.module.lambda_handler({}, None)

        self.assertEqual(result, 42)
        self.dynamodb.update_item.assert_called_once_with(
            TableName='test-counter',
            Key={'id': {'S': '1'}},
            ExpressionAttributeNames={'#views': 'Views'},
            ExpressionAttributeValues={':increment': {'N': '1'}},
            UpdateExpression='ADD #views :increment',
            ReturnValues='ALL_NEW'
        )

    def test_dynamodb_errors_are_not_suppressed(self):
        self.dynamodb.update_item.side_effect = RuntimeError('DynamoDB unavailable')

        with self.assertRaisesRegex(RuntimeError, 'DynamoDB unavailable'):
            self.module.lambda_handler({}, None)


if __name__ == '__main__':
    unittest.main()
