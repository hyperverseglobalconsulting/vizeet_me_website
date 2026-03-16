# =============================================================================
# GitHub Actions OIDC — Keyless Authentication to AWS
# =============================================================================
# This replaces static AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY secrets.
# GitHub Actions exchanges a short-lived OIDC token for temporary AWS creds.
#
# Bootstrap: run `terraform apply` manually from CloudShell once to create
# these IAM resources. After that, all future applies run via the workflow.
# =============================================================================

# GitHub OIDC Identity Provider
# AWS account can only have ONE of these — import if it already exists:
#   aws iam list-open-id-connect-providers
#   terraform import aws_iam_openid_connect_provider.github <arn>
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # sts.amazonaws.com = the audience GitHub sends in its OIDC token
  client_id_list = ["sts.amazonaws.com"]

  # SHA-1 thumbprints of GitHub's OIDC certificate (updated Oct 2023)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "github-oidc-provider"
  }
}

# IAM Role assumed by GitHub Actions via OIDC
resource "aws_iam_role" "github_actions" {
  name        = "github-actions-vizeet-me-website"
  description = "Role assumed by GitHub Actions for vizeet.me website CI/CD (OIDC)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # Must match the audience in the GitHub token
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to only THIS repo (any branch, any event type)
            "token.actions.githubusercontent.com:sub" = "repo:hyperverseglobalconsulting/vizeet_me_website:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-vizeet-me-website"
  }
}

# Scoped inline policy — minimum permissions for the website Terraform workflow
resource "aws_iam_role_policy" "github_actions" {
  name = "vizeet-me-website-ci-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ── Terraform State: S3 bucket ──────────────────────────────────────
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::vizeet-me-terraform-state",
          "arn:aws:s3:::vizeet-me-terraform-state/*"
        ]
      },

      # ── Terraform State: DynamoDB lock table ────────────────────────────
      {
        Sid    = "TerraformStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/terraform-state-lock"
      },

      # ── S3 Website Bucket (us-east-2) ───────────────────────────────────
      {
        Sid    = "WebsiteBucket"
        Effect = "Allow"
        Action = [
          # s3:Get* covers all read operations the AWS provider needs during
          # state refresh (location, versioning, encryption, website, accelerate,
          # acl, cors, logging, notifications, replication, object-lock, etc.)
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketTagging",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::my-portfolio-website-bucket",
          "arn:aws:s3:::my-portfolio-website-bucket/*"
        ]
      },

      # ── CloudFront ──────────────────────────────────────────────────────
      {
        Sid    = "CloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution",
          "cloudfront:ListDistributions",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetOriginAccessControlConfig",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:ListOriginAccessControls",
          "cloudfront:TagResource",
          "cloudfront:UntagResource",
          "cloudfront:ListTagsForResource"
        ]
        Resource = "*"
      },

      # ── ACM Certificate (us-east-1) ─────────────────────────────────────
      {
        Sid    = "ACMCertificate"
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "acm:AddTagsToCertificate"
        ]
        Resource = "*"
      },

      # ── Route53 ─────────────────────────────────────────────────────────
      {
        Sid    = "Route53"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      },

      # ── IAM (read-only — required for Terraform to refresh IAM resources) ─
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListRoleTags"
        ]
        Resource = "*"
      }

    ]
  })
}

# Output the Role ARN — paste this into terraform.yml
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions OIDC — use in workflow role-to-assume"
  value       = aws_iam_role.github_actions.arn
}
