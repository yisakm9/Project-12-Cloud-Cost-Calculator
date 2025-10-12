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