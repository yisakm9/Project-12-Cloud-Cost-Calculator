# dev/modules/s3/variables.tf

variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "cloudfront_oai_iam_arn" {
  description = "The IAM ARN of the CloudFront Origin Access Identity to grant read access."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}