locals {
  cluster_name = "test-cluster"
}


// could use terraform-aws-modules/eks/aws instead of this module
module "eks_cluster" {
  source = "../modules/eks"

  cluster = {
    name    = local.cluster_name
    version = "1.22"
    node_groups = {
      "worker_1" = {
        scaling = {
          min_size     = 1
          max_size     = 3
          desired_size = 2
        }
        instance_type = "t2.small"
      },
      # "worker_2" = {
      #   scaling = {
      #     min_size     = 1
      #     max_size     = 3
      #     desired_size = 2
      #   }
      #   instance_type = "t2.micro"
      # }
    }
  }

  vpc = {
    id                 = module.vpc_and_subnets.vpc_id
    private_subnet_ids = module.vpc_and_subnets.private_subnets
  }
}
