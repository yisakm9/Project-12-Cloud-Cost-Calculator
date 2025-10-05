# dev/modules/sns/variables.tf

variable "topic_name" {
  description = "The name of the SNS topic."
  type        = string
}

variable "email_endpoint" {
  description = "The email address to subscribe to the SNS topic."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}