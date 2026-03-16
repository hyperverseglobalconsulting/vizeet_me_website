# vizeet.me Infrastructure — Current State

> Last updated: 2026-03-16 | Status: ✅ Fully managed by Terraform

## Architecture

```
vizeet.me (Route53)
    │
    ▼
CloudFront Distribution (E1LQW0IG8J5R8W)
    │  - Domain: d3fenqv7dmjqzy.cloudfront.net
    │  - SSL: ACM cert (71bd0b95-...) us-east-1
    │  - Cache: Managed-CachingOptimized policy
    │  - Function: allow-access-to-only-registered-domain (viewer-request)
    │
    ▼
S3 Bucket: my-portfolio-website-bucket (us-east-2 / Ohio)
    │  - Access: CloudFront OAC only (E2991YTMJ4THM3)
    │  - Public access: blocked
    │  - Versioning: enabled
    │  - Encryption: AES256 + bucket key
```

## Resource Inventory

| Resource | Type | ID / Name |
|---|---|---|
| S3 website bucket | `aws_s3_bucket` | `my-portfolio-website-bucket` (us-east-2) |
| S3 public access block | `aws_s3_bucket_public_access_block` | same |
| S3 versioning | `aws_s3_bucket_versioning` | Enabled |
| S3 encryption | `aws_s3_bucket_server_side_encryption_configuration` | AES256 |
| S3 bucket policy | `aws_s3_bucket_policy` | CloudFront OAC only |
| CloudFront OAC | `aws_cloudfront_origin_access_control` | `E2991YTMJ4THM3` |
| CloudFront distribution | `aws_cloudfront_distribution` | `E1LQW0IG8J5R8W` |
| ACM certificate | `aws_acm_certificate` | `71bd0b95-7e3f-449d-998e-0bc57372fc56` |
| Route53 zone | data source | `Z048158418ZLZ49BS7SKI` |
| Route53 A record | `aws_route53_record` | `vizeet.me → CloudFront` |
| Route53 CNAME | `aws_route53_record` | ACM validation record |
| GitHub OIDC provider | `aws_iam_openid_connect_provider` | `token.actions.githubusercontent.com` |
| GitHub Actions IAM role | `aws_iam_role` | `github-actions-vizeet-me-website` |
| IAM inline policy | `aws_iam_role_policy` | `vizeet-me-website-ci-policy` |

## Terraform Backend

| Resource | Value |
|---|---|
| State bucket | `vizeet-me-terraform-state` (us-east-1) |
| State key | `website/terraform.tfstate` |
| Lock table | `terraform-state-lock` (DynamoDB, us-east-1) |

## CI/CD Pipeline

**Authentication**: GitHub OIDC → IAM role `github-actions-vizeet-me-website`
- No static AWS credentials stored anywhere
- Role restricted to `repo:hyperverseglobalconsulting/vizeet_me_website:*`

**Triggers**:
- `push` to `main` with `infra/**` changes → `terraform apply -auto-approve`
- `pull_request` to `main` with `infra/**` changes → `terraform plan` (posted as PR comment)
- `workflow_dispatch` → manual trigger

## Making Infrastructure Changes

1. Edit `.tf` files in `infra/`
2. Run `terraform fmt -recursive ./infra/` locally
3. Open a PR → pipeline posts `terraform plan` as a comment
4. Merge → pipeline runs `terraform apply` automatically

## Key Notes

- **S3 bucket region**: `us-east-2` (Ohio) — uses `aws.us_east_2` provider alias
- **ACM cert region**: `us-east-1` (required for CloudFront)
- **CloudFront function**: `allow-access-to-only-registered-domain` — do NOT remove
- **www.vizeet.me**: No DNS record exists — add `aws_route53_record.website_www` if needed
