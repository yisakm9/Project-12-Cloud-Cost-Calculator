# dev/variables.tf

variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1" # Billing metrics are only available in us-east-1
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
  default     = "your-email@example.com"
}