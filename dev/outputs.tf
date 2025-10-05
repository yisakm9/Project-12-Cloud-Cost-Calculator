# dev/outputs.tf

output "billing_alarm_id" {
  description = "The ID of the created CloudWatch billing alarm."
  value       = module.billing_alarm.alarm_id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for billing alerts."
  value       = module.cost_alerting_topic.topic_arn
}
output "lambda_iam_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  value       = module.lambda_execution_role.role_arn
}