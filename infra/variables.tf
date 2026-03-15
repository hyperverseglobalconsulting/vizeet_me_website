variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
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
  default     = "vizeet-me-website"
}
