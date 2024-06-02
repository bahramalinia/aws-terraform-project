resource "aws_instance" "gitlab_server" {
  ami                           = "ami-052984d1804039ba8"
  instance_type                 = "t3a.large"
  user_data_replace_on_change   = true
  subnet_id                     = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids        = [aws_security_group.gitlab_sg.id, aws_security_group.allow_docker_ports.id]
  key_name                      = aws_key_pair.generated_key.key_name

  provisioner "file" {
    source      = "docker-containers.sh"
    destination = "/home/ec2-user/docker-containers.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "gitlab_server"
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
