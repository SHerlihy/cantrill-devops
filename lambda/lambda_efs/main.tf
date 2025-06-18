terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "cantrill-general-admin"
  region  = "us-east-1"
}

module "vpc" {
    source = "./vpc"
}

module "app" {
  source = "./app"

    vpc_id = module.vpc.vpc_id
    public_subnet = module.vpc.public_subnet
    private_subnet = module.vpc.private_subnet
}

output "efs_dns" {
  value = module.app.efs_dns
}

output "public_subnet" {
  value = module.vpc.public_subnet
}

output "webserver_sg" {
  value = module.app.webserver_sg
}
