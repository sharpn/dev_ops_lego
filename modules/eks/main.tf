###############################################################################
# SECURITY GROUPS
###############################################################################

resource "aws_security_group" "data_plane_sg" {
  name   = "k8s-data-plane-sg"
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "k8s-data-plane-sg"
  }
}

resource "aws_security_group_rule" "nodes" {
  description       = "Allow nodes to communicate with each other"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = flatten([var.private_subnet_cidr_blocks, var.public_subnet_cidr_blocks])
}

resource "aws_security_group_rule" "nodes_inbound" {
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([var.private_subnet_cidr_blocks])
}

resource "aws_security_group_rule" "node_outbound" {
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "control_plane_sg" {
  name   = "k8s-control-plane-sg"
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "k8s-control-plane-sg"
  }
}

# Security group traffic rules
## Ingress rule
resource "aws_security_group_rule" "control_plane_inbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([var.private_subnet_cidr_blocks, var.public_subnet_cidr_blocks])
}

## Egress rule
resource "aws_security_group_rule" "control_plane_outbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

###############################################################################
# IAM
###############################################################################

resource "aws_iam_role" "role" {
  name = "${var.cluster.name}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow"
        Principal : {
          Service : "eks.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachments" {
  for_each = toset([
    "AmazonEKSClusterPolicy",
    "AmazonEKSServicePolicy"
  ])

  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
  role       = aws_iam_role.role.name
}


resource "aws_iam_role" "worker_role" {
  name = "${var.cluster.name}-eks-worker-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "worker_attachments" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "CloudWatchAgentServerPolicy" // allow the workers to send logs
  ])

  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
  role       = aws_iam_role.worker_role.name
}


###############################################################################
# CLUSTER
###############################################################################

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster.name
  role_arn = aws_iam_role.role.arn

  vpc_config {
    subnet_ids = var.vpc.private_subnet_ids
    security_group_ids = [
      aws_security_group.cluster.id
    ]
  }

  version = var.cluster.version



  depends_on = [
    aws_iam_role.role,
    aws_cloudwatch_log_group.control_plane_logs
  ]
}

resource "aws_cloudwatch_log_group" "control_plane_logs" {
  name              = "/aws/eks/${var.cluster.name}/cluster"
  retention_in_days = 30
}

###############################################################################
# CLUSTER SECURITY GROUP
###############################################################################

resource "aws_security_group" "cluster" {
  name_prefix = var.cluster.name
  description = "EKS cluster security group"
  vpc_id      = var.vpc.id

  tags = {
    "Name" = var.cluster.name
  }

  egress { # Outbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress allows Inbound traffic to EKS cluster from the  Internet 
  ingress { # Inbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




###############################################################################
# NODES
###############################################################################

resource "aws_eks_node_group" "node-ec2" {
  for_each = { for key, value in var.cluster.node_groups : key => value }

  cluster_name = aws_eks_cluster.cluster.name

  node_group_name = each.key
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = var.vpc.private_subnet_ids

  scaling_config {
    desired_size = each.value.scaling.desired_size
    max_size     = each.value.scaling.max_size
    min_size     = each.value.scaling.min_size
  }

  instance_types = [each.value.instance_type]
  capacity_type  = "SPOT"
  disk_size      = 20

  depends_on = [
    aws_iam_role.worker_role
  ]
}

