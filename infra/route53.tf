data "aws_route53_zone" "website" {
  name         = var.domain_name
  private_zone = false
}

# ACM DNS validation CNAME — static definition (cert covers vizeet.me only, no SANs)
# Actual record: _2b91f3766875ebc863c64ea70722a625.vizeet.me → acm-validations.aws.
resource "aws_route53_record" "cert_validation" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = "_2b91f3766875ebc863c64ea70722a625.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["_f6ad3c59632723f5efed8b481c546b4a.djqtsrsxkq.acm-validations.aws."]

  allow_overwrite = true
}

# vizeet.me A record — Alias to CloudFront distribution
resource "aws_route53_record" "website" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# NOTE: www.vizeet.me A record does not exist in Route53 - omitted intentionally
# Add back if/when www subdomain is needed
