terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "vizeet-me-terraform-state"
    key            = "website/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "vizeet-me-website"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# S3 bucket lives in us-east-2 (Ohio) — separate provider alias required
provider "aws" {
  alias  = "us_east_2"
  region = var.bucket_region

  default_tags {
    tags = {
      Project     = "vizeet-me-website"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Used to dynamically reference the AWS account ID in IAM policies
data "aws_caller_identity" "current" {}
