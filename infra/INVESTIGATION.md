# Infrastructure Investigation Guide

This guide helps you investigate existing AWS resources before importing them into Terraform.

## Step 1: Identify Existing Resources

### S3 Buckets
```bash
aws s3 ls
aws s3api list-buckets --query 'Buckets[].Name'
```

For each bucket related to the website:
```bash
aws s3api get-bucket-location --bucket <bucket-name>
aws s3api get-bucket-versioning --bucket <bucket-name>
aws s3api get-bucket-encryption --bucket <bucket-name>
aws s3api get-bucket-website --bucket <bucket-name>
aws s3api get-public-access-block --bucket <bucket-name>
```

### CloudFront Distributions
```bash
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Origins.Items[0].DomainName]' --output table
```

For each distribution:
```bash
aws cloudfront get-distribution --id <distribution-id>
aws cloudfront get-distribution-config --id <distribution-id> > cloudfront-config.json
```

### Route53 Hosted Zones
```bash
aws route53 list-hosted-zones
aws route53 list-hosted-zones-by-name --dns-name vizeet.me
```

For each hosted zone:
```bash
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>
```

### ACM Certificates
```bash
aws acm list-certificates --region us-east-1
```

For each certificate:
```bash
aws acm describe-certificate --certificate-arn <cert-arn> --region us-east-1
```

### CloudFront Origin Access Control
```bash
aws cloudfront list-origin-access-controls
```

## Step 2: Document Current State

Create a file `current-state.md` documenting:
- All resource IDs, ARNs, and names
- Current configurations
- Dependencies between resources
- Any custom settings or tags

## Step 3: Prepare Import Commands

Based on the investigation, prepare import commands. Example:

```bash
# Import S3 bucket
terraform import aws_s3_bucket.website <bucket-name>

# Import CloudFront distribution
terraform import aws_cloudfront_distribution.website <distribution-id>

# Import Route53 zone
terraform import aws_route53_zone.website <zone-id>

# Import Route53 records
terraform import aws_route53_record.website <zone-id>_<record-name>_<record-type>

# Import ACM certificate
terraform import aws_acm_certificate.website <certificate-arn>
```

## Step 4: Create Import Script

Use the `import.sh` script to automate the import process after documenting all resources.

## Step 5: Verify Import

After importing:
```bash
terraform plan
```

This should show "No changes" if all resources are correctly imported and match the Terraform configuration.

## Important Notes

1. **Backup First**: Document everything before making changes
2. **Test in Stages**: Import one resource type at a time
3. **Verify State**: Always run `terraform plan` after imports
4. **Update Config**: Adjust Terraform files to match actual resource configurations
5. **State File**: Ensure your state file is properly backed up

## Common Issues

### Resource Already Exists
If Terraform says a resource already exists, it may need to be imported first.

### Configuration Mismatch
If `terraform plan` shows changes after import, update your `.tf` files to match the actual resource configuration.

### Missing Dependencies
Some resources depend on others. Import in this order:
1. S3 buckets
2. ACM certificates
3. CloudFront OAC
4. CloudFront distributions
5. Route53 zones
6. Route53 records
