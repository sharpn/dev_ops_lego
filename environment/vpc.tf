data "aws_availability_zones" "available_zones" {}

module "vpc_and_subnets" {
  source = "../modules/vpc"

  name = "test-vpc"
  cidr = "10.0.0.0/16"

  availability_zones = data.aws_availability_zones.available_zones.names

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}
