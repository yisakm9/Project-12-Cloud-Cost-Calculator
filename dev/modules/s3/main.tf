# dev/modules/s3/main.tf

# Suppress findings that are out of scope for a simple static asset bucket.
#checkov:skip=CKV2_AWS_61:Lifecycle config is not critical for disposable frontend assets.
#checkov:skip=CKV_AWS_144:Cross-region replication is not required for this bucket.
#checkov:skip=CKV2_AWS_62:Event notifications are not required for this bucket.
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

# CKV_AWS_21: Enable versioning to keep a history of objects.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CKV_AWS_145: Enable default server-side encryption for all new objects.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CKV_AWS_18: Configure the bucket to send its access logs to the dedicated logging bucket.
resource "aws_s3_bucket_logging" "this" {
  bucket = aws_s3_bucket.this.id
  target_bucket = var.logging_bucket_id
  target_prefix = "s3-access-logs/${var.bucket_name}/"
}

# This block enforces privacy by blocking all direct public access.
# This resolves CKV_AWS_53, CKV_AWS_54, CKV_AWS_55, and CKV_AWS_56.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# This secure policy grants read-only access ONLY to the specific
# CloudFront Origin Access Identity that is passed into this module.
# This resolves CKV_AWS_70.
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontOAI",
        Effect    = "Allow",
        Principal = {
          AWS = var.cloudfront_oai_iam_arn
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.this]
}