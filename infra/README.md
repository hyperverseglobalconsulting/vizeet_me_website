# Infrastructure as Code

This directory contains Terraform configurations for deploying the vizeet.me website infrastructure on AWS.

## Architecture

The infrastructure includes:

- **S3 Bucket**: Static website hosting with versioning and encryption
- **CloudFront**: CDN distribution for global content delivery
- **ACM Certificate**: SSL/TLS certificate for HTTPS
- **Route53**: DNS management and domain routing

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform >= 1.7.0
3. AWS CLI configured with credentials
4. S3 bucket for Terraform state (update backend configuration in `main.tf`)
5. DynamoDB table for state locking

## Usage

### Initialize Terraform

```bash
cd infra
terraform init
```

### Plan Changes

```bash
terraform plan
```

### Apply Changes

```bash
terraform apply
```

### Destroy Infrastructure

```bash
terraform destroy
```

## Configuration

Update variables in `variables.tf` or create a `terraform.tfvars` file:

```hcl
aws_region  = "us-east-1"
environment = "prod"
domain_name = "vizeet.me"
bucket_name = "vizeet-me-website"
```

## GitHub Actions

The Terraform workflow is automated via GitHub Actions:

- **Validate**: Runs on every push to `infra/**`
- **Plan**: Runs on pull requests
- **Apply**: Runs on push to main branch

### Required Secrets

Add these secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## State Management

Terraform state is stored in S3 with DynamoDB locking. Update the backend configuration in `main.tf` with your bucket details.

## Security

- S3 bucket has public access blocked
- CloudFront uses Origin Access Control (OAC)
- SSL/TLS certificate from ACM
- Server-side encryption enabled on S3
