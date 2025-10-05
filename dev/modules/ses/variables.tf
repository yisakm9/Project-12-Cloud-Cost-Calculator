# dev/modules/ses/variables.tf

variable "email_address" {
  description = "The email address to verify with SES."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}