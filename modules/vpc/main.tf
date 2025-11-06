resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "tf-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "tf-igw" }
}

# public subnets
resource "aws_subnet" "public" {
  for_each = toset(var.public_azs)
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(var.public_azs, each.key) * 2) # simple derive
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = { Name = "public-${each.key}" }
}

# private subnets
resource "aws_subnet" "private" {
  for_each = toset(var.private_azs)
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(var.private_azs, each.key) * 2 + 1)
  availability_zone = each.key
  map_public_ip_on_launch = false
  tags = { Name = "private-${each.key}" }
}

# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (one in first public subnet)
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(values(aws_subnet.public).*id, 0)
  tags = { Name = "tf-nat" }
}

# private route table -> NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = aws_route_table.private.id
}

