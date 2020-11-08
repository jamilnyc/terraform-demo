import json

def lambda_handler(event, context):
    messages = event['Records']
    print("Batch Size:", len(messages))
    for m in messages:
        print(m['body'])
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from the Terraform Lambda!')
    }
