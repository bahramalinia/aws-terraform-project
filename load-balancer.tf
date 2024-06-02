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
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.gitlab_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab_tg.arn
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

  depends_on = [aws_instance.gitlab_server]
}
