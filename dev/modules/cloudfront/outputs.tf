# dev/modules/cloudfront/outputs.tf

output "oai_iam_arn" {
  description = "The IAM ARN for the Origin Access Identity, used in the S3 bucket policy."
  value       = aws_cloudfront_origin_access_identity.oai.iam_arn
}

output "distribution_domain_name" {
  description = "The public domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}