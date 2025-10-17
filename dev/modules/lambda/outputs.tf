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