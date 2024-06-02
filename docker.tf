# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

# resource "docker_image" "grafana" {
#   name = "grafana/grafana:latest"
# }

# resource "docker_container" "grafana" {
#   image = docker_image.grafana.latest
#   name  = "grafana"
#   ports {
#     internal = 3000
#     external = 3000
#   }
# }

# resource "docker_image" "nexus" {
#   name = "sonatype/nexus3:latest"
# }

# resource "docker_container" "nexus" {
#   image = docker_image.nexus.latest
#   name  = "nexus"
#   ports {
#     internal = 8081
#     external = 8081
#   }
# }

# resource "docker_image" "jenkins" {
#   name = "jenkins/jenkins:lts"
# }

# resource "docker_container" "jenkins" {
#   image = docker_image.jenkins.latest
#   name  = "jenkins"
#   ports {
#     internal = 8080
#     external = 8080
#   }
#   env = [
#     "JENKINS_OPTS=--prefix=/jenkins"
#   ]
# }
