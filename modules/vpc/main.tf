resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

  enable_dns_hostnames = true

  tags = {
    "Name" = var.name
  }
}


###############################################################################
# PUBLIC
###############################################################################

resource "aws_route_table" "public_route_table" {
  count = length(var.public.subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.name}-public"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public.subnets) > 0 ? length(var.public.subnets) : 0

  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public.subnets, count.index)

  availability_zone    = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) > 0 ? element(var.availability_zones, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) == 0 ? element(var.availability_zones, count.index) : null

  tags = merge({
    Name = format("${var.name}-public-%s", element(var.availability_zones, count.index))
  }, var.public.tags, var.tags)
}

###############################################################################
# PRIVATE
###############################################################################

resource "aws_route_table" "private_route_table" {
  count = length(var.private.subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.name}-private"
  }
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

###############################################################################
# NAT
###############################################################################

resource "aws_eip" "external_nat_ip" {
  vpc = true

  tags = {
    Name = "${var.name}-nat-ip"
  }
}

locals {
  nat_gateway_ips = try(aws_eip.external_nat_ip[*].id, [])
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = element(local.nat_gateway_ips, 0)
  subnet_id     = element(aws_subnet.public_subnet[*].id, 0)

  tags = merge({
    Name = format("${var.name}-%s", element(var.availability_zones, 0))
  }, var.tags)

  depends_on = [
    aws_internet_gateway.internet_gateway
  ]
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = element(aws_route_table.private_route_table[*].id, 0)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gateway[*].id, 0)

  timeouts {
    create = "5m"
  }
}

###############################################################################
# INTERNET GATEWAY
###############################################################################

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}"
  }
}

###############################################################################
# ROUTE TABLES
###############################################################################

resource "aws_route_table_association" "private_route_associations" {
  count = length(var.private.subnets) > 0 ? length(var.private.subnets) : 0

  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.private_route_table[*].id, 0)
}

resource "aws_route_table_association" "public_route_associations" {
  count = length(var.public.subnets) > 0 ? length(var.public.subnets) : 0

  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_route_table[0].id
}
