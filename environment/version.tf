terraform {
  backend "s3" {
    bucket         = "sharpn-terraform-state" // change this to your bucket name
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "sharpn_state_lock" // change this to your dynamodb table name
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

  experiments = [module_variable_optional_attrs]

  required_version = ">=1.1.9"
}
