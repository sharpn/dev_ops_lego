terraform {
  backend "s3" {
    bucket = "sharpn-terraform-state" // change this to your bucket name
    key    = "global/s3/terraform.tfstate"
    region = "eu-west-2"

    # dynamodb_table = "sharpn_terraform_lock" // change this to your dynamodb table name
    # encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.11"
    }
  }

  required_version = ">=1.0.11"
}
