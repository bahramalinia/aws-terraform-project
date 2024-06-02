resource "null_resource" "gitlab_setup" {
  depends_on = [aws_instance.gitlab_server, aws_eip.gitlab_eip]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_eip.gitlab_eip.public_ip
      timeout     = "2m"
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
