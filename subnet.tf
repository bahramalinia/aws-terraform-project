resource "aws_subnet" "public" {
  count = 3

  vpc_id            = data.aws_vpc.default.id
  cidr_block        = count.index == 0 ? "172.31.112.0/20" : count.index == 1 ? "172.31.128.0/20" : "172.31.144.0/20"
  availability_zone = count.index == 0 ? "eu-west-3a" : count.index == 1 ? "eu-west-3b" : "eu-west-3c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}
