# Request an ACM certificate
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

# Create Route 53 records for domain validation
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

# Verify the certificate once the validation records are created
resource "aws_acm_certificate_validation" "gitlab_cert_validation" {
  certificate_arn         = aws_acm_certificate.gitlab_cert.arn
  validation_record_fqdns = [for k, v in aws_route53_record.gitlab_cert_validation : v.fqdn]

  depends_on = [aws_route53_record.gitlab_cert_validation]
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id            = data.aws_vpc.default.id
  cidr_block        = count.index == 0 ? "172.31.112.0/20" : count.index == 1 ? "172.31.128.0/20" : "172.31.144.0/20"
  availability_zone = count.index == 0 ? "eu-west-3a" : count.index == 1 ? "eu-west-3b" : "eu-west-3c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_lb" "gitlab_lb" {
  name               = "gitlab-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gitlab_sg.id]
  subnets            = aws_subnet.public.*.id


  enable_deletion_protection = false
}

resource "aws_lb_listener" "gitlab_https" {
  load_balancer_arn = aws_lb.gitlab_lb.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.gitlab_cert.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.gitlab_tg.arn
  }
}


resource "aws_security_group" "lb_sg" {
  name_prefix = "gitlab-lb-sg"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "gitlab_tg" {
  name     = "gitlab-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  tags = {
    Name = "gitlab-tg"
  }
}

resource "aws_lb_target_group_attachment" "gitlab_attachment" {
  target_group_arn = aws_lb_target_group.gitlab_tg.arn
  target_id        = aws_instance.gitlab_server.id
  port             = 80
}

# Fetch the existing ACM certificate
data "aws_acm_certificate" "gitlab_cert" {
  domain   = "gitlab.aliniacoding.com"
  statuses = ["ISSUED"]

  depends_on = [aws_acm_certificate_validation.gitlab_cert_validation]
}

# Use the certificate ARN in your Helm values file
output "acm_certificate_arn" {
  value = data.aws_acm_certificate.gitlab_cert.arn
}