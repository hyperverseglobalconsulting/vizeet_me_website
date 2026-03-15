#!/bin/bash

# Terraform Import Script for Existing Infrastructure
# This script helps import existing AWS resources into Terraform state

set -e

echo "==================================="
echo "Terraform Import Script"
echo "==================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

print_info "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure'."
    exit 1
fi

print_info "AWS credentials verified."
echo ""

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init
echo ""

# Prompt for resource information
echo "Please provide the following information about your existing resources:"
echo ""

read -p "S3 Bucket Name (press Enter to skip): " BUCKET_NAME
read -p "CloudFront Distribution ID (press Enter to skip): " CF_DIST_ID
read -p "Route53 Hosted Zone ID (press Enter to skip): " ZONE_ID
read -p "ACM Certificate ARN (press Enter to skip): " CERT_ARN
read -p "CloudFront OAC ID (press Enter to skip): " OAC_ID

echo ""
print_info "Starting import process..."
echo ""

# Import S3 Bucket
if [ ! -z "$BUCKET_NAME" ]; then
    print_info "Importing S3 bucket: $BUCKET_NAME"
    if terraform import aws_s3_bucket.website "$BUCKET_NAME" 2>/dev/null; then
        print_info "✓ S3 bucket imported successfully"
        
        # Import related S3 resources
        terraform import aws_s3_bucket_versioning.website "$BUCKET_NAME" 2>/dev/null || print_warning "Could not import bucket versioning"
        terraform import aws_s3_bucket_server_side_encryption_configuration.website "$BUCKET_NAME" 2>/dev/null || print_warning "Could not import bucket encryption"
        terraform import aws_s3_bucket_public_access_block.website "$BUCKET_NAME" 2>/dev/null || print_warning "Could not import public access block"
        terraform import aws_s3_bucket_website_configuration.website "$BUCKET_NAME" 2>/dev/null || print_warning "Could not import website configuration"
        terraform import aws_s3_bucket_policy.website "$BUCKET_NAME" 2>/dev/null || print_warning "Could not import bucket policy"
    else
        print_warning "S3 bucket already imported or does not exist"
    fi
    echo ""
fi

# Import ACM Certificate
if [ ! -z "$CERT_ARN" ]; then
    print_info "Importing ACM certificate: $CERT_ARN"
    if terraform import aws_acm_certificate.website "$CERT_ARN" 2>/dev/null; then
        print_info "✓ ACM certificate imported successfully"
    else
        print_warning "ACM certificate already imported or does not exist"
    fi
    echo ""
fi

# Import CloudFront OAC
if [ ! -z "$OAC_ID" ]; then
    print_info "Importing CloudFront OAC: $OAC_ID"
    if terraform import aws_cloudfront_origin_access_control.website "$OAC_ID" 2>/dev/null; then
        print_info "✓ CloudFront OAC imported successfully"
    else
        print_warning "CloudFront OAC already imported or does not exist"
    fi
    echo ""
fi

# Import CloudFront Distribution
if [ ! -z "$CF_DIST_ID" ]; then
    print_info "Importing CloudFront distribution: $CF_DIST_ID"
    if terraform import aws_cloudfront_distribution.website "$CF_DIST_ID" 2>/dev/null; then
        print_info "✓ CloudFront distribution imported successfully"
    else
        print_warning "CloudFront distribution already imported or does not exist"
    fi
    echo ""
fi

# Import Route53 Hosted Zone
if [ ! -z "$ZONE_ID" ]; then
    print_info "Importing Route53 hosted zone: $ZONE_ID"
    if terraform import aws_route53_zone.website "$ZONE_ID" 2>/dev/null; then
        print_info "✓ Route53 hosted zone imported successfully"
    else
        print_warning "Route53 hosted zone already imported or does not exist"
    fi
    echo ""
fi

echo ""
print_info "Import process completed!"
echo ""
print_warning "IMPORTANT: Run 'terraform plan' to verify the import and identify any configuration differences."
print_warning "You may need to adjust your .tf files to match the actual resource configurations."
echo ""
print_info "Next steps:"
echo "  1. Run: terraform plan"
echo "  2. Review any differences"
echo "  3. Update .tf files to match existing resources"
echo "  4. Run: terraform plan (should show no changes)"
echo ""
