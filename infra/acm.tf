resource "aws_acm_certificate" "website" {
  provider          = aws
  domain_name       = var.domain_name
  validation_method = "DNS"

  # NOTE: Actual cert has no SANs - only covers vizeet.me (0 additional names)
  # subject_alternative_names removed to match existing certificate

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "vizeet-me-website-cert"
  }
}

# NOTE: aws_acm_certificate_validation intentionally omitted.
# The certificate is already in "Issued" state and DNS validation is complete.
# The validation CNAME record is managed separately as aws_route53_record.cert_validation.
