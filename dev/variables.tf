# dev/variables.tf

variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1" # Billing metrics are only available in  us-east-1
}

variable "billing_alarm_threshold" {
  description = "The threshold for the billing alarm in USD."
  type        = number
  default     = 100
}

variable "sns_topic_name" {
  description = "The name for the SNS topic used for billing alerts."
  type        = string
  default     = "aws-billing-alerts"
}

variable "notification_email" {
  description = "The email address to receive billing notifications."
  type        = string
  # IMPORTANT: Update this with your actual email address
  default     = "yisakmesifin@gmail.com"
}
variable "lambda_iam_role_name" {
  description = "The name for the IAM role to be used by the cost-reporting Lambda function."
  type        = string
  default     = "CostReportLambdaRole"
}
variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
  default     = "GetWeeklyCostReport"
}

variable "lambda_schedule" {
  description = "Cron expression for how often the Lambda should run."
  type        = string
  # default     = "cron(0 9 ? * MON *)" # Every Monday at 9:00 AM UTC
  default     = "rate(2 minutes)" 
}