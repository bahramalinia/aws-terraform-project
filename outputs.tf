# output "cluster_arn" {
#   value = module.eks.cluster_arn
# }

# output "cluster_version" {
#   value = module.eks.cluster_version
# }

# output "kubeconfig" {
#   value = yamlencode({
#     apiVersion = "v1"
#     kind       = "Config"
#     clusters = [
#       {
#         name = "cluster"
#         cluster = {
#           server                     = module.eks.cluster_endpoint
#           certificate-authority-data = module.eks.cluster_certificate_authority_data
#         }
#       },
#     ]
#     contexts = [
#       {
#         name = "context"
#         context = {
#           cluster = "cluster"
#           user    = "aws"
#         }
#       },
#     ]
#     current-context = "context"
#     users = [
#       {
#         name = "aws"
#         user = {
#           exec = {
#             apiVersion = "client.authentication.k8s.io/v1beta1"
#             command    = "aws"
#             args       = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#           }
#         }
#       },
#     ]
#   })
#   sensitive = true
# }

output "region" {
  description = "AWS region"
  value       = var.region
}

output "subnet_ids" {
  value = { for id in data.aws_subnets.default.ids : id => id }
}

output "public_ip" {
  value = aws_instance.gitlab_server.public_ip
}

output "instance_id" {
  value = aws_instance.gitlab_server.id
}

output "instance_public_ip" {
  value = aws_instance.gitlab_server.public_ip
}