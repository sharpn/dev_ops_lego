data "aws_iam_policy_document" "node_policy_document" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
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


resource "aws_iam_role" "nodes_role" {
  name               = "${var.cluster.name}-eks-worker-role"
  assume_role_policy = data.aws_iam_policy_document.node_policy_document.json
}


resource "aws_iam_role_policy_attachment" "nodes_role_attachments" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "CloudWatchAgentServerPolicy" // allow the workers to send logs
  ])

  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
  role       = aws_iam_role.nodes_role.name
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
      aws_security_group.eks_cluster.id,
      aws_security_group.eks_nodes.id
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
# NODES
###############################################################################

resource "aws_eks_node_group" "node-ec2" {
  for_each = { for key, value in var.cluster.node_groups : key => value }

  cluster_name = aws_eks_cluster.cluster.name

  node_group_name = each.key
  node_role_arn   = aws_iam_role.nodes_role.arn
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
    aws_iam_role_policy_attachment.nodes_role_attachments
  ]
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster.name}-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                        = "${var.cluster.name}-sg"
    "kubernetes.io/cluster/${var.cluster.name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_role_attachments
  ]
}

###############################################################################
# SECURITY GROUPS
###############################################################################

resource "aws_security_group" "eks_cluster" {
  name        = var.cluster.name
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc.id

  tags = {
    Name = var.cluster.name
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}
