# dev/modules/lambda/outputs.tf

output "function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.cost_report_lambda.arn
}

output "function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.cost_report_lambda.function_name
}