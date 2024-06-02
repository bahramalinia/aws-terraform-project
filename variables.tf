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
  default = "../new-key-pair.pem"

}

variable "key_name" {
  description = "The name of the key pair"
  default     = "aliniacoding keypair"  # Update with your key pair name
}

variable "gitlab_hostname" {
  description = "host name for tiglab"
  default     = "gitlab.aliniacoding.com"
}



