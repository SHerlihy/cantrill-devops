def lambda_handler(event, context):   
    return {
        'statusCode': 200,
        'headers': {},
        'body': event['requestContext']['identity']['sourceIp'],
        'isBase64Encoded': False
        }
