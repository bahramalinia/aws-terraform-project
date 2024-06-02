resource "aws_acm_certificate" "gitlab_cert" {
  domain_name       = "gitlab.aliniacoding.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "GitLab Certificate"
  }
}

resource "aws_acm_certificate_validation" "gitlab_cert_validation" {
  certificate_arn         = aws_acm_certificate.gitlab_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.gitlab_cert_validation : record.fqdn]
}
