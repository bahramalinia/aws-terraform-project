data "aws_route53_zone" "selected" {
  name         = "aliniacoding.com."
  private_zone = false
}

resource "aws_route53_record" "gitlab_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id  # or replace with your hosted zone ID if known
  name    = "gitlab.aliniacoding.com"
  type    = "A"

  alias {
    name                   = aws_lb.gitlab_lb.dns_name
    zone_id                = aws_lb.gitlab_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_eip" "gitlab_eip" {
  depends_on = [aws_instance.gitlab_server]
  vpc = true  # Ensure this is set to true to create an EIP for VPC

  instance = aws_instance.gitlab_server.id

  tags = {
    Name = "GitlabEIP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_eip" "www" {
#   vpc = true  # Ensure this is set to true to create an EIP for VPC

#   instance = aws_instance.gitlab_server.id

#   tags = {
#     Name = "GitlabEIP"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.selected.zone_id  # or replace with your hosted zone ID if known
#   name    = "www.aliniacoding.com"
#   type    = "A"
#   ttl     = "300"
#   records = [aws_eip.gitlab_eip.public_ip]
# }


