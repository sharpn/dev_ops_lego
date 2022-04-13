resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({
    "Name" = var.name
  }, var.tags)
}

###############################################################################
# SUBNETS
###############################################################################

resource "aws_subnet" "public_subnet" {
  count = length(var.public.subnets) > 0 ? length(var.public.subnets) : 0

  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public.subnets, count.index)

  availability_zone    = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) > 0 ? element(var.availability_zones, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) == 0 ? element(var.availability_zones, count.index) : null

  tags = merge({
    Name = format("${var.name}-public-%s", element(var.availability_zones, count.index))
  }, var.public.tags, var.tags)

  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private.subnets) > 0 ? length(var.private.subnets) : 0

  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private.subnets, count.index)

  availability_zone    = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) > 0 ? element(var.availability_zones, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) == 0 ? element(var.availability_zones, count.index) : null

  tags = merge({
    Name = format("${var.name}-private-%s", element(var.availability_zones, count.index))
  }, var.private.tags, var.tags)
}

################################################################################
# ROUTING
################################################################################

# public subnet routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "public-routing-table"
  }
}

# allow traffic to the internet for the public subnets
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public.subnets)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# private subnet routing table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private-routing-table"
  }
}

// allow traffic to the internet from private subnets
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private.subnets)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}


###############################################################################
# INTERNET GATEWAY
###############################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

################################################################################
# NAT
################################################################################

resource "aws_eip" "main" {
  vpc = true
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "NAT Gateway for Custom Kubernetes Cluster"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

################################################################################
# SECURITY GROUPS
################################################################################

resource "aws_security_group" "default" {
  name        = "default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
}
