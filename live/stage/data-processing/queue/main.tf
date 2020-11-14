# Create an SQS queue and Lambda Function that processes queue messages
# The queue receives messages from an SNS topic
# This assumes an SNS topic already exists somewhere that you will subscribe to
# We are not creating one in this module

provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

###############################
### SQS QUEUE CONFIGURATION ###
###############################

# Create a basic SQS Queue
resource "aws_sqs_queue" "q" {
  name = "MyQueueTerraform"

  # Time until message is retried after a failure
  visibility_timeout_seconds = 120

  message_retention_seconds = (60 * 60 * 24 * 4) # 4 days
  delay_seconds = 0
  max_message_size = 262144 # 256 KiB

  # A higher time is longer polling, which would reduce costs
  receive_wait_time_seconds = 20

  # Messages will be tried by the Lambda function maxReceiveCount times
  # before the queue gives up on it and sends it to the Dead Letter Queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount = 10
  })
}

# Policy document for the queue, allowing the resource(s) with the matching ARN to send messages to it.
# The intention here is that the SNS topic's ARN will be used here so only that topic will push to the queue
# But you can also make use of wildcards for the ARN
data "aws_iam_policy_document" "terraform_query_policy_doc" {
  statement {
    sid = "topic-subscription-terraform-JamilsTopic"
    effect = "Allow"
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    actions = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.q.arn]

    condition {
      test = "ArnEquals"
      values = [var.sns_topic_arn]
      variable = "aws:SourceArn"
    }
  }
}

# Policy object that connects the document defined above to the actual queue created
resource "aws_sqs_queue_policy" "q_policy" {
  policy = data.aws_iam_policy_document.terraform_query_policy_doc.json
  queue_url = aws_sqs_queue.q.id
}

# It's not enough that the SNS topic *can* push to the queue
# The queue must also be subscribed to the topic, listening for incoming messages
resource "aws_sns_topic_subscription" "subscription_to_sns" {
  endpoint = aws_sqs_queue.q.arn
  protocol = "sqs"
  topic_arn = var.sns_topic_arn
}

#####################################
### LAMBDA FUNCTION CONFIGURATION ###
#####################################

# The actual code of the lambda function, zipped up by terraform
data "archive_file" "lambda_code" {
  type = "zip"
  source_file = "lambda.py"
  output_path = "lambda.py.zip"
}

# Define the Lambda Function, it's code source, runtime and other features
resource "aws_lambda_function" "queue_lambda" {
  function_name = "QueueMessageProcessTerraform"

  # Configure runtime environment and code
  filename = data.archive_file.lambda_code.output_path
  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  # Format is file_name.function_name
  handler = "lambda.lambda_handler"
  runtime = "python3.8"

  timeout = 30
  memory_size = 128

  # Role that allows operations on queue and writing to log files
  role = aws_iam_role.lambda_role.arn
}

# This Lambda Function is triggered by messages being sent to the queue
resource "aws_lambda_event_source_mapping" "lambda_trigger" {
  event_source_arn = aws_sqs_queue.q.arn
  function_name = aws_lambda_function.queue_lambda.arn

  # Up to batch_size messages can be sent at a time for batch processing to this function/
  batch_size = 1
  enabled = true
}

# Define a policy document for the Lambda function
data "aws_iam_policy_document" "terraform_lambda_sqs_policy_doc" {
  version = "2012-10-17"

  # Permission to create a Log Group
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:us-east-1:838267569814:*"]
  }

  # Permission to write to logs in this group
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:us-east-1:838267569814:log-group:/aws/lambda/${aws_lambda_function.queue_lambda.function_name}:*"]
  }

  # Permission to receive, read and delete messages from the queue defined above
  statement {
    effect = "Allow"
    actions = ["SQS:DeleteMessage", "SQS:GetQueueAttributes", "SQS:ReceiveMessage"]
    resources = [aws_sqs_queue.q.arn]
  }
}

# Create a policy with this document
resource "aws_iam_policy" "lambda_sqs_management_policy" {
  policy = data.aws_iam_policy_document.terraform_lambda_sqs_policy_doc.json
}

# Define the role that the Lambda function will assume
resource "aws_iam_role" "lambda_role" {
  name = "LambdaQueueConsumerRoleTerraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the policy to the Lambda function's assumed role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_sqs_management_policy.arn
  role = aws_iam_role.lambda_role.name
}