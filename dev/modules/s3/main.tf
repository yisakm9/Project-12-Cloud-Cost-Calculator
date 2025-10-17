# dev/modules/s3/main.tf

# This resource creates the S3 bucket. It is no longer configured for public access.
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

# The aws_s3_bucket_website_configuration resource has been DELETED as it is no longer needed.

# This block is now configured to ENFORCE privacy by blocking all direct public access.
# This resolves CKV_AWS_53, CKV_AWS_54, CKV_AWS_55, and CKV_AWS_56.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

