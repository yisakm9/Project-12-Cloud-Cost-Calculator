# dev/modules/cloudwatch/outputs.tf

output "alarm_arn" {
  description = "The ARN of the CloudWatch Billing Alarm."
  value       = aws_cloudwatch_metric_alarm.billing_alarm.arn
}

output "alarm_id" {
  description = "The ID of the CloudWatch Billing Alarm."
  value       = aws_cloudwatch_metric_alarm.billing_alarm.id
}