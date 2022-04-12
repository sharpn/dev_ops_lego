data "aws_availability_zones" "available_zones" {}


// Could use terraform-aws-modules/vpc/aws instead of this module
module "vpc_and_subnets" {
  source = "../modules/vpc"

  name = "test-vpc"
  cidr = "10.0.0.0/16"

  availability_zones = data.aws_availability_zones.available_zones.names

  private = {
    subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    tags = {
      "kubernetes.io/role/elb" = "1"
    }
  }

  public = {
    subnets = ["10.0.3.0/24", "10.0.4.0/24"]
    tags = {
      "kubernetes.io/role/internal-elb" = "1"
    }
  }

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
