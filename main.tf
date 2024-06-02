
terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.51.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.4"
    }
  }

  required_version = "~> 1.3"
}

# Data source to fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to fetch the default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source to fetch the existing Internet Gateway in the default VPC
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a Route Table in the default VPC
resource "aws_route_table" "default_route_table" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = {
    Name = "default_route_table"
  }
}

# Associate the Route Table with all subnets in the default VPC
resource "aws_route_table_association" "default" {
  for_each       = toset(data.aws_subnets.default.ids)
  subnet_id      = each.value
  route_table_id = aws_route_table.default_route_table.id
}

# Create Security Group allowing HTTP and HTTPS traffic
resource "aws_security_group" "gitlab_sg" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gitlab_sg"
  }
}

provider "aws" {
  region = var.region
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = "my-generated-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/new-key-pair.pem"
  file_permission = "0600"
}

# Define an EC2 instance (GitLab server)
resource "aws_instance" "gitlab_server" {
  ami                           = "ami-052984d1804039ba8"  # Change to your preferred AMI
  instance_type                 = "t3a.large"
  user_data_replace_on_change   = true
  subnet_id                     = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids        = [aws_security_group.gitlab_sg.id]
  key_name                      = aws_key_pair.generated_key.key_name

  tags = {
    Name = "gitlab_server"
  }
}

resource "null_resource" "gitlab_setup" {
  depends_on = [aws_instance.gitlab_server, aws_eip.gitlab_eip]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user" // "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_eip.gitlab_eip.public_ip
      timeout     = "2m"  # Increase timeout for longer operations
    }

    inline = [
      "echo 'Starting script execution' > /home/ec2-user/script_log.txt 2>&1",
      "sudo yum update -y && echo 'yum update completed' >> /home/ec2-user/script_log.txt 2>&1",
      "sudo yum install -y docker && echo 'Docker installed' >> /home/ec2-user/script_log.txt 2>&1",
      "sudo service docker start && echo 'Docker service started' >> /home/ec2-user/script_log.txt 2>&1",
      "sudo usermod -aG docker ec2-user && echo 'Added ec2-user to docker group' >> /home/ec2-user/script_log.txt 2>&1",
      "sudo mkdir -p /srv/gitlab/config /srv/gitlab/logs /srv/gitlab/data",
      "sudo docker run --detach --hostname ${var.gitlab_hostname} --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://${var.gitlab_hostname}'\" --publish 443:443 --publish 80:80 --publish 2222:22 --name gitlab --restart always --volume /srv/gitlab/config:/etc/gitlab --volume /srv/gitlab/logs:/var/log/gitlab --volume /srv/gitlab/data:/var/opt/gitlab --shm-size 256m gitlab/gitlab-ee:latest && echo 'GitLab container started' >> /home/ec2-user/script_log.txt 2>&1 || echo 'Failed to start GitLab container' >> /home/ec2-user/script_log.txt 2>&1"
    ]

  }
}


data "aws_route53_zone" "selected" {
  name         = "aliniacoding.com."
  private_zone = false
}

resource "aws_lb" "gitlab_lb" {
  name               = "gitlab-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gitlab_sg.id]
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = false
}

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


resource "aws_eip" "gitlab_eip" {
  vpc      = true
  instance = aws_instance.gitlab_server.id

  tags = {
    Name = "GitlabEIP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

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

resource "aws_acm_certificate_validation" "gitlab_cert_validation" {
  certificate_arn         = aws_acm_certificate.gitlab_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.gitlab_cert_validation : record.fqdn]
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

  depends_on = [aws_instance.gitlab_server]
}


# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

# variable "cluster_name" {
#   description = "The name of the EKS cluster"
#   type        = string
#   default     = "gitlab-eks"
# }

variable "public_key_path" {
  description = "Path to the public key to be used for the AWS key pair"
  type        = string
  default     = "~/.ssh/id_rsa.pub"  # Change this to where your public SSH key is stored
}
variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  default     = "./new-key-pair.pem"
}


variable "key_name" {
  description = "The name of the key pair"
  default     = "aliniacoding keypair"  # Update with your key pair name
}

variable "gitlab_hostname" {
  description = "host name for tiglab"
  default     = "gitlab.aliniacoding.com"
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

output "gitlab_server_ip" {
  value = aws_eip.gitlab_eip.public_ip
}

output "instance_id" {
  value = aws_instance.gitlab_server.id
}

output "instance_public_ip" {
  value = aws_eip.gitlab_eip.public_ip
}

output "public_ip" {
  value = aws_eip.gitlab_eip.public_ip
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "subnet_ids" {
  value = { for id in data.aws_subnets.default.ids : id => id }
}





