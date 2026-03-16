# =============================================================================
# smiles2mol — AWS infrastructure (us-east-2) managed as Terraform
# =============================================================================
# Existing resources (created manually before this repo existed):
#   ECR:      rdkit-lambda         → imported via terraform import
#   Lambda:   rdkit-lambda         → imported via terraform import
#   Route53:  projects.vizeet.me A record → uses allow_overwrite
#
# IMPORT COMMANDS (run once from CloudShell after terraform init):
#   terraform import -chdir=infra aws_ecr_repository.rdkit_lambda rdkit-lambda
#   terraform import -chdir=infra aws_lambda_function.rdkit_lambda rdkit-lambda
#   terraform import -chdir=infra aws_route53_record.projects \
#     Z048158418ZLZ49BS7SKI_projects.vizeet.me_A
# =============================================================================

# ── ECR Repository ─────────────────────────────────────────────────────────
# Import: terraform import aws_ecr_repository.rdkit_lambda rdkit-lambda
resource "aws_ecr_repository" "rdkit_lambda" {
  provider             = aws.us_east_2
  name                 = "rdkit-lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "rdkit-lambda-ecr"
  }
}

resource "aws_ecr_lifecycle_policy" "rdkit_lambda" {
  provider   = aws.us_east_2
  repository = aws_ecr_repository.rdkit_lambda.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# ── Lambda execution role (data source — role already exists) ───────────────
# We reference the existing role rather than recreating it.
# To find the role name: aws lambda get-function-configuration
#   --function-name rdkit-lambda --region us-east-2 --query Role
data "aws_iam_role" "rdkit_lambda" {
  name = "rdkit-lambda-role-a2973bwz" # service-role created by Lambda console
}

# ── Lambda function (container image) ──────────────────────────────────────
# Import: terraform import aws_lambda_function.rdkit_lambda rdkit-lambda
resource "aws_lambda_function" "rdkit_lambda" {
  provider      = aws.us_east_2
  function_name = "rdkit-lambda"
  role          = data.aws_iam_role.rdkit_lambda.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.rdkit_lambda.repository_url}:latest"
  timeout       = 843  # intentionally high — complex SMILES can be slow to render
  memory_size   = 128

  lifecycle {
    # The CI pipeline updates image_uri via `aws lambda update-function-code`.
    # Prevent Terraform from reverting that on the next apply.
    ignore_changes = [image_uri, role, timeout]
  }

  tags = { Name = "rdkit-lambda" }
}

# Allow API Gateway (RDKitRESTAPI lyjh31sb0b) to invoke rdkit-lambda
resource "aws_lambda_permission" "rdkit_lambda_apigw" {
  provider      = aws.us_east_2
  statement_id  = "01ecd21a-272f-555b-97b6-d76e65740979"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rdkit_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-2:${data.aws_caller_identity.current.account_id}:lyjh31sb0b/*/POST/smiles2mol"
}

# ── Route53 A record: projects.vizeet.me → API Gateway regional domain ─────
# Import: terraform import aws_route53_record.projects \
#   Z048158418ZLZ49BS7SKI_projects.vizeet.me_A
resource "aws_route53_record" "projects" {
  zone_id         = data.aws_route53_zone.website.zone_id
  name            = "projects.vizeet.me"
  type            = "A"
  allow_overwrite = true # Record already exists — overwrite rather than error

  alias {
    name                   = "d-npjc1qezy0.execute-api.us-east-2.amazonaws.com"
    zone_id                = "ZOJJZC49E0EPZ" # API Gateway us-east-2 hosted zone
    evaluate_target_health = false
  }
}

# ── Outputs ─────────────────────────────────────────────────────────────────
output "rdkit_lambda_ecr_url" {
  description = "ECR repository URL for rdkit-lambda — used by CI deploy workflow"
  value       = aws_ecr_repository.rdkit_lambda.repository_url
}

output "smiles2mol_endpoint" {
  description = "Public API endpoint"
  value       = "https://projects.vizeet.me/smiles2mol"
}
