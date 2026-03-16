# Infrastructure variables for vizeet.me website

variable "aws_region" {
  description = "AWS region for CloudFront, ACM, Route53, and Terraform backend"
  type        = string
  default     = "us-east-1"
}

variable "bucket_region" {
  description = "AWS region where the S3 website bucket lives (us-east-2 / Ohio)"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
  default     = "vizeet.me"
}

variable "bucket_name" {
  description = "S3 bucket name for website hosting"
  type        = string
  default     = "my-portfolio-website-bucket"
}
