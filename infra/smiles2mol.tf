# =============================================================================
# smiles2mol — Existing AWS infrastructure imported into Terraform (us-east-2)
# =============================================================================
# All resources below already exist. They were created manually and are being
# brought under Terraform management via `terraform import`.
#
# Architecture:
#   GitHub Pages (webpage.html)
#     → POST https://projects.vizeet.me/smiles2mol
#     → API Gateway custom domain (projects.vizeet.me, us-east-2)
#     → RDKitRESTAPI (lyjh31sb0b) /smiles2mol POST → rdkit-lambda
#     → ECR image: 093487613626.dkr.ecr.us-east-2.amazonaws.com/rdkit-lambda:latest
#
# Import commands (run once to adopt existing state):
#   terraform import -var-file=... aws_ecr_repository.rdkit_lambda rdkit-lambda
#   terraform import aws_lambda_function.rdkit_lambda rdkit-lambda        (us-east-2)
#   terraform import aws_api_gateway_rest_api.rdkit lyjh31sb0b            (us-east-2)
#   terraform import aws_api_gateway_domain_name.projects projects.vizeet.me (us-east-2)
#   terraform import aws_api_gateway_base_path_mapping.smiles2mol projects.vizeet.me//  (us-east-2)
#   terraform import aws_route53_record.projects Z048158418ZLZ49BS7SKI_projects.vizeet.me_A
# =============================================================================

# ── Provider alias for us-east-2 (already declared in main.tf) ────────────
# All smiles2mol resources use the aws.us_east_2 provider alias.

# ── ECR Repository ─────────────────────────────────────────────────────────
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

# ── Lambda execution role ───────────────────────────────────────────────────
resource "aws_iam_role" "rdkit_lambda" {
  name        = "rdkit-lambda-execution-role"
  description = "Execution role for rdkit-lambda function (smiles2mol)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "rdkit-lambda-role" }
}

resource "aws_iam_role_policy_attachment" "rdkit_lambda_basic" {
  role       = aws_iam_role.rdkit_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── Lambda function (container image) ──────────────────────────────────────
resource "aws_lambda_function" "rdkit_lambda" {
  provider      = aws.us_east_2
  function_name = "rdkit-lambda"
  role          = aws_iam_role.rdkit_lambda.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.rdkit_lambda.repository_url}:latest"
  timeout       = 30
  memory_size   = 128

  lifecycle {
    # CI pipeline updates the image via `aws lambda update-function-code`.
    # Prevent Terraform from reverting that on the next apply.
    ignore_changes = [image_uri]
  }

  tags = { Name = "rdkit-lambda" }
}

# Allow API Gateway (RDKitRESTAPI) to invoke rdkit-lambda
resource "aws_lambda_permission" "rdkit_lambda_apigw" {
  provider      = aws.us_east_2
  statement_id  = "01ecd21a-272f-555b-97b6-d76e65740979"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rdkit_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-2:${data.aws_caller_identity.current.account_id}:lyjh31sb0b/*/POST/smiles2mol"
}

# ── Route53 A record: projects.vizeet.me → API Gateway regional domain ─────
resource "aws_route53_record" "projects" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = "projects.vizeet.me"
  type    = "A"

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
