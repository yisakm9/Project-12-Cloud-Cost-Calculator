# dev/modules/kms/variables.tf

variable "alias_name" {
  description = "The alias for the KMS key (e.g., 'my-app-key')."
  type        = string
}

variable "description" {
  description = "A description for the KMS key."
  type        = string
}

variable "allow_cloudwatch_logs" {
  description = "If true, attaches a policy allowing the CloudWatch Logs service to use this key."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}