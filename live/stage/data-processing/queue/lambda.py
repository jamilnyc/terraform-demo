import json

def lambda_handler(event, context):
    messages = event['Records']
    print("Batch Size:", len(messages))
    for m in messages:
        print(m['body'])

        if ('I am an error' in m['body']):
            print('Whoops, there was an error. I will now throw an exception. Bye.')
            raise Exception('The lambda function found an error! Oh, no!')


    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
