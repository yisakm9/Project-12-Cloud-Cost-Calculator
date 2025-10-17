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