# dev/modules/cloudfront/variables.tf

variable "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket origin (e.g., bucket-name.s3.us-east-1.amazonaws.com)."
  type        = string
}
variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
variable "logging_bucket_domain_name" {
  description = "The domain name of the S3 bucket for access logs."
  type        = string
}