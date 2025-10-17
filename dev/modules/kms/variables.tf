variable "alias_name" {
  description = "The alias for the KMS key."
  type        = string
}
variable "description" {
  description = "A description for the KMS key."
  type        = string
}
variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
variable "allow_cloudwatch_logs" {
  description = "If true, attaches a policy allowing CloudWatch Logs service to use this key."
  type        = bool
  default     = false
}