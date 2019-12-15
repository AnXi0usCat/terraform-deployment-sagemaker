import os
import boto3
import json

# grab environment variables
ENDPOINT_NAME = os.environ['ENDPOINT_NAME']
runtime = boto3.client('runtime.sagemaker')

def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))
    body = json.loads(event['body'])
    print(ENDPOINT_NAME)
    message = 'Hello, my name is {} and {}'.format(body["firstname"], body["surname"])
    #response = runtime.invoke_endpoint(EndpointName=ENDPOINT_NAME,
    #                                   ContentType='text/csv',
    #                                   Body=payload)
    #print(response)
    #result = json.loads(response['Body'].read().decode())
    #print(result)
    #pred = int(result['predictions'][0]['predicted_label'])
    
    #return pred
    return {
        'statusCode' : 200,
        'headers' : { 'Content-Type' : 'application/json', 'Access-Control-Allow-Origin' : '*' },
        'body' : json.dumps({'code': 200, 'message': message})
    }

