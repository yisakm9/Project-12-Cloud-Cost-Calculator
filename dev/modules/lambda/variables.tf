# dev/modules/lambda/variables.tf

variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "The runtime environment for the Lambda function."
  type        = string
  default     = "python3.11"
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  type        = string
}

variable "source_code_path" {
  description = "The path to the Lambda function's source code."
  type        = string
}

variable "schedule_expression" {
  description = "The schedule for triggering the Lambda function (cron or rate expression). Null if not scheduled."
  type        = string
  default     = null # Allow it to be nullable
}



variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
variable "kms_key_arn" {
  description = "The ARN of the KMS key for encrypting environment variables."
  type        = string
  default     = null # Make it optional
}
# Also update the environment variables to be a map
variable "environment_variables" {
  description = "A map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}