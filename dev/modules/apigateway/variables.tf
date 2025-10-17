# dev/modules/apigateway/variables.tf

variable "api_name" {
  description = "The name of the HTTP API Gateway."
  type        = string
}

variable "lambda_integration_arn" {
  description = "The ARN of the Lambda function to integrate with the API."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
variable "aws_account_id" {
  description = "The AWS Account ID where the resources are deployed."
  type        = string
}

variable "aws_region" {
  description = "The AWS Region where the resources are deployed."
  type        = string
}