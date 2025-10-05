# dev/modules/iam/variables.tf

variable "role_name" {
  description = "The name of the IAM role."
  type        = string
}

variable "policy_name" {
  description = "The name of the IAM policy."
  type        = string
}

variable "role_description" {
  description = "The description of the IAM role."
  type        = string
  default     = "IAM role for Lambda function execution"
}

variable "policy_description" {
  description = "The description of the IAM policy."
  type        = string
  default     = "IAM policy for Lambda to access necessary AWS services"
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}