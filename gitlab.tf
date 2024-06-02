
# resource "helm_release" "gitlab" {
#   name       = "gitlab"
#   chart      = "gitlab/gitlab"
#   version    = "7.11.1"  // Confirm the current chart version

#   namespace  = "default"

#   set {
#     name  = "global.hosts.domain"
#     value = "aliniacoding.com"  # Use your actual domain
#   }

#   set {
#     name  = "global.hosts.externalIP"
#     value = "${aws_eip.gitlab_eip.public_ip}"
#   }

#   set {
#     name  = "certmanager-issuer.email"
#     value = "sana.aliniaa@gmail.com" 
#   }

#   set {
#     name  = "nginx-ingress.controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
#     value = "nlb"
#   }

#   set {
#     name  = "postgresql.image.tag"
#     value = "14"  # PostgreSQL image tag
#   }

#   values = [
#     file("helm/gitlab-values.yaml")
#   ]

#   timeout = 300  # seconds
# }
