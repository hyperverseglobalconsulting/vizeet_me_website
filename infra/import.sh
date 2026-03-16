#!/bin/bash
# =============================================================================
# Terraform Import Script for vizeet.me Website Infrastructure
# =============================================================================
# Run this from the infra/ directory after:
#   1. terraform init
#   2. Reviewing each import line is correct
# =============================================================================

set -e  # Stop on any error

# ── Confirmed Resource IDs ──────────────────────────────────────────────────
ACCOUNT_ID="093487613626"
S3_BUCKET="my-portfolio-website-bucket"
CF_DIST_ID="E1LQW0IG8J5R8W"
CF_OAC_ID="E2991YTMJ4THM3"
ACM_CERT_ARN="arn:aws:acm:us-east-1:${ACCOUNT_ID}:certificate/71bd0b95-7e3f-449d-998e-0bc57372fc56"
ZONE_ID="Z048158418ZLZ49BS7SKI"

echo "=============================================="
echo "  Terraform Import for vizeet.me infra"
echo "=============================================="
echo ""

# ── 1. S3 Bucket ───────────────────────────────────────────────────────────
echo "[1/8] Importing S3 bucket: ${S3_BUCKET}"
terraform import aws_s3_bucket.website "${S3_BUCKET}"

# ── 2. S3 Public Access Block ──────────────────────────────────────────────
echo "[2/8] Importing S3 public access block"
terraform import aws_s3_bucket_public_access_block.website "${S3_BUCKET}"

# ── 3. S3 Versioning ───────────────────────────────────────────────────────
echo "[3/8] Importing S3 versioning config"
terraform import aws_s3_bucket_versioning.website "${S3_BUCKET}"

# ── 4. S3 Encryption ───────────────────────────────────────────────────────
echo "[4/8] Importing S3 encryption config"
terraform import aws_s3_bucket_server_side_encryption_configuration.website "${S3_BUCKET}"

# ── 5. S3 Bucket Policy ────────────────────────────────────────────────────
echo "[5/8] Importing S3 bucket policy"
terraform import aws_s3_bucket_policy.website "${S3_BUCKET}"

# ── 6. CloudFront OAC ──────────────────────────────────────────────────────
echo "[6/8] Importing CloudFront Origin Access Control: ${CF_OAC_ID}"
terraform import aws_cloudfront_origin_access_control.website "${CF_OAC_ID}"

# ── 7. CloudFront Distribution ─────────────────────────────────────────────
echo "[7/8] Importing CloudFront distribution: ${CF_DIST_ID}"
terraform import aws_cloudfront_distribution.website "${CF_DIST_ID}"

# ── 8. ACM Certificate ─────────────────────────────────────────────────────
echo "[8/8] Importing ACM certificate"
terraform import aws_acm_certificate.website "${ACM_CERT_ARN}"

# ── Route53: data source (no import needed) ────────────────────────────────
# data.aws_route53_zone.website is a DATA SOURCE — Terraform looks it up
# automatically by name (vizeet.me). No import required.

# ── Route53 Records ────────────────────────────────────────────────────────
echo ""
echo "NOTE: Route53 record imports require the exact record name."
echo "Run these manually after the above complete:"
echo ""
echo "  # vizeet.me A record (alias to CloudFront)"
echo "  terraform import aws_route53_record.website ${ZONE_ID}_vizeet.me_A"
echo ""
echo "  # ACM validation CNAME record"
echo "  terraform import 'aws_route53_record.cert_validation[\"vizeet.me\"]' \\"
echo "    ${ZONE_ID}__2b91f3766875ebc863c64ea70722a625.vizeet.me_CNAME"
echo ""

echo "=============================================="
echo "  ✅ Core imports complete!"
echo "  Now run: terraform plan"
echo "  Goal: 'No changes' — if there are diffs,"
echo "  update the .tf files to match and re-plan."
echo "=============================================="
