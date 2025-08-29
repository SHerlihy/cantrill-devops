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

variable "db_subnets" {
    type = set(string)
}

variable "efs_subnets" {
    type = set(string)
}

module "db" {
  source = "./db"

  subnets = var.db_subnets 
}

module "efs" {
  source = "./efs"

  subnets = var.efs_subnets
}
