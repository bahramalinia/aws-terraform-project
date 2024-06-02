variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "public_key_path" {
  description = "Path to the public key to be used for the AWS key pair"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  default     = "./new-key-pair.pem"
}

variable "key_name" {
  description = "The name of the key pair"
  default     = "aliniacoding keypair"
}

variable "gitlab_hostname" {
  description = "Host name for GitLab"
  default     = "gitlab.aliniacoding.com"
}
