# dev/modules/cloudwatch/variables.tf

variable "alarm_name" {
  description = "The name for the CloudWatch metric alarm."
  type        = string
  default     = "Billing-Alarm"
}

variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified statistic and threshold."
  type        = string
  default     = "GreaterThanOrEqualToThreshold"
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "metric_name" {
  description = "The name for the alarm's associated metric."
  type        = string
  default     = "EstimatedCharges"
}

variable "namespace" {
  description = "The namespace for the alarm's associated metric."
  type        = string
  default     = "AWS/Billing"
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 21600 # 6 hours
}

variable "statistic" {
  description = "The statistic to apply to the alarm's associated metric."
  type        = string
  default     = "Maximum"
}

variable "threshold" {
  description = "The value against which the specified statistic is compared."
  type        = number
}

variable "alarm_description" {
  description = "The description for the alarm."
  type        = string
  default     = "Alarm when AWS spending exceeds the defined threshold"
}

variable "dimensions" {
  description = "The dimensions for the alarm's associated metric."
  type        = map(string)
  default = {
    "Currency" = "USD"
  }
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic to notify when the alarm transitions into an ALARM state."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}