# dev/modules/s3/variables.tf

variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}
variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
variable "logging_bucket_id" {
  description = "The ID of the S3 bucket to use for access logging."
  type        = string
}