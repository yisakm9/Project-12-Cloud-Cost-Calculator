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

output "lambda_function_arn" {
  description = "The ARN of the cost reporting Lambda function."
  value       = module.cost_report_function.function_arn
}
output "ses_verified_email_arn" {
  description = "The ARN of the SES email identity. Manual email confirmation is required."
  value       = module.ses_email_identity.identity_arn
}
output "dashboard_url" {
  description = "The URL for the cost calculator dashboard."
  value       = module.cost_dashboard_bucket.website_endpoint
}
output "s3_bucket_name" {
  description = "The name of the S3 bucket for the dashboard."
  value       = module.cost_dashboard_bucket.bucket_name
}
output "api_endpoint_url" {
  description = "The base URL for the Cost Data API Gateway."
  value       = module.cost_api.api_endpoint
}