data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_route53_zone" "selected" {
  name         = "aliniacoding.com."
  private_zone = false
}

data "aws_acm_certificate" "gitlab_cert" {
  domain   = "gitlab.aliniacoding.com"
  statuses = ["ISSUED"]

  depends_on = [aws_acm_certificate_validation.gitlab_cert_validation]
}
