# dev/modules/lambda/outputs.tf

output "function_arn" {
  description = "The ARN of the Lambda function."
  # --- USE THE CORRECT RESOURCE NAME 'this' ---
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "The name of the Lambda function."
  # --- USE THE CORRECT RESOURCE NAME 'this' ---
  value       = aws_lambda_function.this.function_name
}
output "dlq_arn" {
  description = "The ARN of the SQS Dead Letter Queue."
  value       = one(aws_sqs_queue.lambda_dlq[*].arn) # Use the `one()` function to handle the count
}