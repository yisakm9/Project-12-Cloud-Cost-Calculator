# dev/modules/iam/outputs.tf

output "role_arn" {
  description = "The ARN of the IAM role for Lambda."
  value       = aws_iam_role.lambda_exec_role.arn
}

output "role_name" {
  description = "The name of the IAM role for Lambda."
  value       = aws_iam_role.lambda_exec_role.name
}