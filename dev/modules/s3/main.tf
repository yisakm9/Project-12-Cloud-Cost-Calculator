# dev/modules/s3/main.tf

# Suppress findings that are out of scope for a simple static asset bucket.
#checkov:skip=CKV2_AWS_61:Lifecycle config is not critical for disposable frontend assets.
#checkov:skip=CKV_AWS_144:Cross-region replication is not required for this bucket.
#checkov:skip=CKV2_AWS_62:Event notifications are not required for this bucket.
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  bucket = aws_s3_bucket.this.id
  target_bucket = var.logging_bucket_id
  target_prefix = "s3-access-logs/${var.bucket_name}/"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# NOTE: The aws_s3_bucket_policy is intentionally NOT in this file.