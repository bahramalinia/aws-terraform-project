resource "aws_route53_record" "gitlab_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "gitlab.aliniacoding.com"
  type    = "A"

  alias {
    name                   = aws_lb.gitlab_lb.dns_name
    zone_id                = aws_lb.gitlab_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.gitlab_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}
