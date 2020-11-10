# Create a dead letter queue to house messages that have failed repeatedly and are not processable

resource "aws_sqs_queue" "dlq" {
  name = "MyDeadLetterQueueTerraform"
  visibility_timeout_seconds = 30
  message_retention_seconds = (60 * 60 * 24 * 10)
  delay_seconds = 0
  max_message_size = 262144
  receive_wait_time_seconds = 20
}

data "aws_iam_policy_document" "terraform_dlq_policy_doc" {
  statement {
    sid = "terraform-dlq-policy-statement"
    effect = "Allow"
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    actions = ["SQS:*"]
    resources = [aws_sqs_queue.dlq.arn]

    # Only the original queue can operate on this DLQ
    condition {
      test = "ArnEquals"
      values = [aws_sqs_queue.q.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "dlq_policy" {
  policy = data.aws_iam_policy_document.terraform_dlq_policy_doc.json
  queue_url = aws_sqs_queue.dlq.id
}