############################################
# CloudFront Origin Access Control (OAC)
############################################

resource "aws_cloudfront_origin_access_control" "frontend" {

  name                              = "${var.project}-${var.environment}-oac"
  description                       = "OAC for Frontend S3 Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

}

############################################
# CloudFront Distribution
############################################

resource "aws_cloudfront_distribution" "frontend" {

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Frontend Distribution"
  default_root_object = "index.html"

  origin {

    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "frontend-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id

  }

  default_cache_behavior {

    target_origin_id = "frontend-s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    compress = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

  }

  restrictions {

    geo_restriction {
      restriction_type = "none"
    }

  }

  viewer_certificate {

    cloudfront_default_certificate = true

  }

  price_class = "PriceClass_100"

  tags = {
    Name        = "Frontend CloudFront"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}
