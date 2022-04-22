locals {
  cluster_name = "${var.environment_name}-cluster"
  nodes_map = { for key, value in var.cluster["nodes"] : "node_pool_${key}" => {
    scaling = {
      min_size     = value.min_size,
      max_size     = value.max_size,
      desired_size = value.desired_size
    }
    instance_type = value.instance_type != null ? value.instance_type : "t2.micro"
  } }
}

// could use terraform-aws-modules/eks/aws instead of this module
module "eks_cluster" {
  source = "../modules/eks"

  cluster = {
    name    = local.cluster_name
    version = var.cluster["version"]

    node_groups = local.nodes_map
  }

  vpc = {
    id                 = module.vpc_and_subnets.vpc_id
    private_subnet_ids = module.vpc_and_subnets.private_subnets
  }
}
