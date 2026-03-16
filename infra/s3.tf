# NOTE: Bucket 'my-portfolio-website-bucket' is in us-east-2 (Ohio)
# All S3 resources must use the aws.us_east_2 provider alias

resource "aws_s3_bucket" "website" {
  provider = aws.us_east_2
  bucket   = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "website" {
  provider = aws.us_east_2
  bucket   = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "website" {
  provider = aws.us_east_2
  bucket   = aws_s3_bucket.website.id

  versioning_configuration {
    # NOTE: versioning was previously Disabled on the bucket.
    # Setting to Enabled is an intentional improvement for this managed state.
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  provider = aws.us_east_2
  bucket   = aws_s3_bucket.website.id

  rule {
    # bucket_key_enabled = true matches the actual bucket configuration
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# NOTE: aws_s3_bucket_website_configuration intentionally omitted.
# This bucket uses CloudFront + OAC for direct S3 access — static website
# hosting is NOT enabled on the bucket (confirmed via get-bucket-website).

resource "aws_s3_bucket_policy" "website" {
  provider = aws.us_east_2
  bucket   = aws_s3_bucket.website.id

  # Policy matches the actual bucket policy exactly (Id, Version, Sid preserved)
  policy = jsonencode({
    Id      = "PolicyForCloudFrontPrivateContent"
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}
