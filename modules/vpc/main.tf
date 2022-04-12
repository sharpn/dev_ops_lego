resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

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

###############################################################################
# INTERNET GATEWAY
###############################################################################

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.name}"
  }, var.tags)
}

###############################################################################
# ROUTING
###############################################################################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge({
    "Name" = "${var.name}-public"
  }, var.tags)
}

resource "aws_route_table" "private_route_table" {
  count = length(var.private.subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge({
    "Name" = "${var.name}-private"
  }, var.tags)
}

###############################################################################
# ROUTE ASSOCIATIONS
###############################################################################

resource "aws_route_table_association" "internet_access" {
  count = length(var.public.subnets) > 0 ? length(var.public.subnets) : 0

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.main.id
}


###############################################################################
# NAT
###############################################################################

resource "aws_eip" "external_nat_ip" {
  vpc = true

  tags = merge({
    Name = "${var.name}-nat-ip"
  }, var.tags)
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
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id

  timeouts {
    create = "5m"
  }
}

###############################################################################
# SECURITY GROUPS
###############################################################################

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group_rule" "sg_ingress_public_443" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

esource "aws_security_group_rule" "sg_ingress_public_80" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

## Egress rule
resource "aws_security_group_rule" "sg_egress_public" {
  security_group_id = aws_security_group.public_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
