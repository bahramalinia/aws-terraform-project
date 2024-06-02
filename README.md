
## AWS CLI Configuration

Ensure you have the AWS CLI installed and configured with the necessary credentials:

1. **Install AWS CLI**: Follow the [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

2. **Configure AWS CLI**:

   ```sh
   aws configure
   ```

   Provide your AWS Access Key ID, Secret Access Key, default region name, and default output format when prompted.

## kubeconfig Configuration

Update your `kubeconfig` to use your EKS cluster:

```sh
aws eks update-kubeconfig --name gitlab-eks --region eu-west-3
```

**Note**: This assumes that there is already an EKS cluster named `gitlab-eks` created on `default vpc`.  If not, you need to first run `terraform apply` or `terraform apply -target=module.eks`

Verify the configuration:

```sh
kubectl get nodes
```

## Certificate Manager Settings

Install Cert-Manager in your Kubernetes cluster to handle TLS certificates:

1. **Install Cert-Manager**:

   ```sh
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml --validate=false
   ```

2. **Create a ClusterIssuer for Let's Encrypt**:

   Save the following as `cluster-issuer.yaml`:

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-prod
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: your-email@example.com
       privateKeySecretRef:
         name: letsencrypt-prod
       solvers:
       - http01:
           ingress:
             class: nginx
   ```

   Apply the configuration:

   ```sh
   kubectl apply -f cluster-issuer.yaml
   ```

## DNS Settings and Testing

1. **Configure Route 53 DNS**:

   - Navigate to Route 53 in the AWS Console.
   - Select your hosted zone for `aliniacoding.com`.
   - Create a new A record:
     - **Name**: `gitlab`
     - **Type**: A
     - **Value**: Public IP address of your GitLab instance (`aws_eip.gitlab_eip.public_ip`).

2. **Verify DNS Resolution**:

   From your local machine:

   ```sh
   nslookup gitlab.aliniacoding.com
   ```

   From within the Kubernetes cluster:

   ```sh
   kubectl run -it --rm --image=alpine dns-test -- sh
   nslookup gitlab.aliniacoding.com
   ```

## Route 53 Notes

- Ensure that the A record for `gitlab.aliniacoding.com` correctly points to the public IP address assigned to your GitLab instance.
- Verify that your domain and DNS settings propagate correctly.

## Other Important Things for Developers

- **Helm Provider Configuration**: Ensure that the Helm provider in Terraform is correctly configured with the EKS cluster endpoint and authentication token.

  Example `provider.tf`:

  ```hcl
  data "aws_eks_cluster" "cluster" {
    name = module.eks.cluster_name
  }

  data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_name
  }

  provider "kubernetes" {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }

  provider "helm" {
    kubernetes {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }
  }

  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.47.0"
      }
      kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "~> 2.0"
      }
      helm = {
        source  = "hashicorp/helm"
        version = "~> 2.0"
      }
    }

    required_version = "~> 1.3"
  }
  ```

- **PostgreSQL Configuration**: Ensure the PostgreSQL version matches the initialized data directory. Update the `postgresql.image.tag` in the Helm release configuration if necessary.

- **Deployment Verification**: After applying the Terraform configuration, verify the status of the GitLab pods and check their logs for any issues.

  ```sh
  kubectl get pods -n default
  kubectl logs gitlab-postgresql-0
  kubectl logs gitlab-gitlab-runner-d8c5ff4f4-mrs6d
  ```

By following these steps and configurations, you should be able to deploy GitLab successfully using Terraform and Helm.

# Launch a hello world app on your EC2 instance

To launch a "Hello World" web application on your domain `www.aliniacoding.com` using AWS services, you'll need to set up a few components: a web server to host your application, and potentially a deployment mechanism to manage your code. Below is a step-by-step guide on how to do this using Amazon EC2 (Elastic Compute Cloud) for the server and Route 53 for DNS management:

### Step 1: Set up an EC2 Instance
1. **Log in to the AWS Management Console** and navigate to the EC2 dashboard.
2. **Launch a new EC2 instance**:
   - Choose an appropriate Amazon Machine Image (AMI), such as Amazon Linux 2 or Ubuntu.
   - Select an instance type (e.g., `t2.micro`, which is eligible for the free tier).
   - Configure instance details as per your requirement, setting the correct VPC and subnet.
   - Add storage if the default isn’t sufficient.
   - Configure a security group to allow HTTP (port 80) and HTTPS (port 443) traffic, as well as SSH (port 22) for remote access.
   - Review and launch the instance, creating or selecting an existing key pair for SSH access.

### Step 2: Install Web Server Software
After setting up your instance, you need to install web server software. Here's how to do it for a basic "Hello World" application using Nginx and Node.js:
1. **Connect to your instance via SSH** using the key pair you selected or created during the setup.
   ```bash
   ssh -i "your-key-pair.pem" ec2-user@your-instance-public-dns.amazonaws.com
   ```
2. **Update your package manager** and install Nginx:
   ```bash
   sudo yum update -y  # For Amazon Linux or CentOS
   sudo apt update && sudo apt upgrade -y  # For Ubuntu
   sudo yum install nginx -y  # For Amazon Linux or CentOS
   sudo apt install nginx -y  # For Ubuntu
   ```
3. **Start the Nginx service** and ensure it runs on boot:
   ```bash
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```
4. **Install Node.js** (optional, if you are planning to run a Node.js app):
   ```bash
   curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
   sudo yum install nodejs -y  # For Amazon Linux or CentOS
   sudo apt install nodejs -y  # For Ubuntu
   ```
5. **Create your web application**:
   - For a simple static HTML site, you can edit the default Nginx root document located at `/usr/share/nginx/html/index.html`.
   - For a Node.js app, create a new directory, initialize a Node.js project, and write your app.

### Step 3: Configure DNS
1. **Return to the Route 53 console** and navigate to your hosted zone.
2. **Create or ensure that an A record exists** pointing to the Elastic IP or public IP of your EC2 instance:
   - Name: `www`
   - Type: A – IPv4 address
   - Value: `<Your-EC2-instance's-public-IP>`

### Step 4: Test Your Website
- After setting everything up and DNS records have propagated, open a web browser and go to `http://www.aliniacoding.com`. You should see your "Hello World" page.

This guide gives you a basic setup. Depending on your requirements, you might want to explore additional AWS services or configurations, like Elastic Load Balancing, Auto Scaling, AWS Lambda for serverless deployments, or Amazon S3 for static website hosting if you do not require server-side processing.

# Useful commands

```
kubectl get ingress 
ws acm describe-certificate --certificate-arn arn:aws:acm:eu-west-3:849749410199:certificate/11f46391-2fb0-4d5b-b725-65f4ea4a4339
aws route53 list-resource-record-sets --hosted-zone-id Z01685731FU9J0R5WRRX1  
```

# Troubleshoot

## Getting Gitlab root password

```
# ssh to EC2 machine
docker ps
docker exec -it CONTAINER_ID cat /etc/gitlab/initial_root_password

```