resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "my-portfolio-website-bucket.s3.us-east-2.amazonaws.com"
  description                       = "OAC for vizeet.me website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  aliases             = [var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    # origin_id must match the actual value in CloudFront (not a custom label)
    origin_id                = "my-portfolio-website-bucket.s3.us-east-2.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my-portfolio-website-bucket.s3.us-east-2.amazonaws.com"

    # AWS Managed Cache Policy: CachingOptimized
    # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
    # ID: 658327ea-f89d-4fab-a63d-7e88639e58f6
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # CloudFront Function: restricts access to only the registered domain (vizeet.me)
    function_association {
      event_type   = "viewer-request"
      function_arn = "arn:aws:cloudfront::093487613626:function/allow-access-to-only-registered-domain"
    }
  }

  # NOTE: 403/404 custom error responses are NOT currently configured on the distribution.
  # Uncomment below to enable SPA-style error routing (serves index.html for 403/404):
  # custom_error_response {
  #   error_code         = 403
  #   response_code      = 200
  #   response_page_path = "/index.html"
  # }
  # custom_error_response {
  #   error_code         = 404
  #   response_code      = 200
  #   response_page_path = "/index.html"
  # }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "vizeet-me-website-cdn"
  }
}
