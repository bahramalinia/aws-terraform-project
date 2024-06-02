# Define an EC2 instance (GitLab server)
resource "aws_instance" "gitlab_server" {
  ami                    = "ami-00ac45f3035ff009e"  # Change to your preferred AMI
  instance_type          = "t3.medium"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.gitlab_sg.id]  # Use security group IDs here
  key_name               = aws_key_pair.generated_key.key_name


  # Ubuntu user: ubuntu
  # user_data = <<-EOF
  #             #!/bin/bash
  #             apt-get update -y
  #             apt-get install -y nginx
  #             systemctl start nginx
  #             systemctl enable nginx
  #             echo 'Hello World from Terraform!' > /var/www/html/index.html
              
              # Install Certbot
              # apt-get install -y software-properties-common
              # add-apt-repository -y universe
              # add-apt-repository -y ppa:certbot/certbot
              # apt-get update -y
              # apt-get install -y certbot python3-certbot-nginx

              # # Obtain and install the certificate
              # certbot --nginx -d gitlab.aliniacoding.com --non-interactive --agree-tos -m your-email@example.com

              # # Reload Nginx to apply the certificate
              # systemctl reload nginx
              # EOF
  tags = {
    Name = "gitlab_server"
  }
}
# data "aws_eip" "gitlab_eip" {
#   public_ip = "15.237.85.130" 
# }
resource "null_resource" "gitlab_setup" {
  depends_on = [aws_instance.gitlab_server, aws_eip.gitlab_eip]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_eip.gitlab_eip.public_ip
      timeout     = "2m"  # Increase timeout for longer operations
    }

    inline = [
      "echo 'Starting script execution' > /home/ubuntu/script_log.txt 2>&1",
      "sudo apt-get update -y && echo 'apt-get update completed' > /home/ubuntu/script_log.txt 2>&1",
      "sudo apt-get install -y docker.io && echo 'Docker installed' > /home/ubuntu/script_log.txt 2>&1",
      "sudo mkdir -p /srv/gitlab/config /srv/gitlab/logs /srv/gitlab/data",
      "sudo docker run --detach --hostname ${var.gitlab_hostname} --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://${var.gitlab_hostname}'\" --publish 443:443 --publish 80:80 --publish 2222:22 --name gitlab --restart always --volume /srv/gitlab/config:/etc/gitlab --volume /srv/gitlab/logs:/var/log/gitlab --volume /srv/gitlab/data:/var/opt/gitlab --shm-size 256m gitlab/gitlab-ce:16.10.6-ce && echo 'GitLab container started' > /home/ubuntu/script_log.txt 2>&1 || echo 'Failed to start GitLab container' > /home/ubuntu/script_log.txt 2>&1"
    ]
  }
}

# Default security group
data "aws_security_group" "default_sg" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}
