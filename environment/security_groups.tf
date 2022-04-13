locals {
  public_sg_rules = {
    sg_ingress_public_443 = {
      security_group_id = aws_security_group.public_sg.id
      type              = "ingress"
      from_port         = 443
      to_port           = 443
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
    },
    sg_ingress_public_80 = {
      security_group_id = aws_security_group.public_sg.id
      type              = "ingress"
      from_port         = 80
      to_port           = 80
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
    },
    sg_egress_public = {
      security_group_id = aws_security_group.public_sg.id
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }

  data_plane_rules = {
    nodes = {
      description       = "Allow the nodes to communicate with each other"
      security_group_id = aws_security_group.data_plane_sg.id

      type      = "ingress"
      from_port = 0
      to_port   = 65535
      protocol  = "-1"

      cidr_blocks = flatten([
        module.vpc_and_subnets.public_cidr_blocks,
        module.vpc_and_subnets.private_cidr_blocks,
      ])
    },
    nodes_inbound = {
      description       = "Allow worker kubelets to recieve communication from the API server"
      security_group_id = aws_security_group.data_plane_sg.id

      type      = "ingress"
      from_port = 1025
      to_port   = 65535
      protocol  = "tcp"

      cidr_blocks = flatten([module.vpc_and_subnets.private_cidr_blocks])
    },
    node_outbound = {
      security_group_id = aws_security_group.data_plane_sg.id
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }

  control_plane_rules = {
    control_plane_inbound = {
      security_group_id = aws_security_group.control_plane_sg.id
      type              = "ingress"
      from_port         = 0
      to_port           = 65535
      protocol          = "tcp"
      cidr_blocks = flatten([
        module.vpc_and_subnets.public_cidr_blocks,
        module.vpc_and_subnets.private_cidr_blocks,
      ])
    },
    control_plane_outbound = {
      security_group_id = aws_security_group.control_plane_sg.id
      type              = "egress"
      from_port         = 0
      to_port           = 65535
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }
}

###############################################################################
# PUBLIC
###############################################################################

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = module.vpc_and_subnets.vpc_id

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group_rule" "public_rules" {
  for_each = local.public_sg_rules

  security_group_id = each.value.security_group_id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks

  depends_on = [aws_security_group.public_sg]
}

###############################################################################
# DATA PLANE
###############################################################################

resource "aws_security_group" "data_plane_sg" {
  name   = "kube_data_plane_sg"
  vpc_id = module.vpc_and_subnets.vpc_id

  tags = {
    name = "kube_data_plane_sg"
  }
}

resource "aws_security_group_rule" "node_rules" {
  for_each = local.data_plane_rules

  description       = try(each.value.desciption, null)
  security_group_id = each.value.security_group_id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol

  cidr_blocks = each.value.cidr_blocks

  depends_on = [
    aws_security_group.data_plane_sg
  ]
}

###############################################################################
# CONTROL PLANE
###############################################################################

resource "aws_security_group" "control_plane_sg" {
  name   = "k8s-control-plane-sg"
  vpc_id = module.vpc_and_subnets.vpc_id

  tags = {
    Name = "k8s-control-plane-sg"
  }
}

resource "aws_security_group_rule" "control_plane_rules" {
  for_each = local.control_plane_rules

  security_group_id = each.value.security_group_id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}
