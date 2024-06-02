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