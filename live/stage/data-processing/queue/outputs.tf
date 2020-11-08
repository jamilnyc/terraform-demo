output "policy_text" {
  value = data.aws_iam_policy_document.terraform_query_policy_doc.json
  description = "The JSON Document attached to the Queue"
}

output "queue_endpoint" {
  value = aws_sqs_queue.q.id
  description = "The Unique Identifier of the Queue that was created"
}