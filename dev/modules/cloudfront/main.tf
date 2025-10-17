# dev/modules/cloudfront/main.tf

# Create a special identity that CloudFront will use to access the private S3 bucket.
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for the cost calculator dashboard S3 bucket"
}

# The CloudFront distribution. This is the public-facing CDN.
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for the cost calculator dashboard"
  default_root_object = "index.html"

  # Origin configuration: points to our S3 bucket.
  origin {
    domain_name = var.s3_bucket_regional_domain_name
    origin_id   = "S3-${var.s3_bucket_regional_domain_name}"

    # This crucial block tells CloudFront to use the special OAI to access S3.
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Default cache behavior: how requests are handled.
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_regional_domain_name}"

    # Standard caching policy for web assets.
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Viewer certificate configuration for HTTPS.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Restrictions for the distribution.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags
}

