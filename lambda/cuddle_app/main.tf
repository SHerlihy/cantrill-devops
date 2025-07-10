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

module "messager" {
  source = "./messager"
}

module "ingest" {
  source = "./ingest"

  state_machine_arn = module.messager.state_machine_arn
}

module "frontend" {
  source = "./frontend"

  api_url = module.ingest.api_url
}

output "frontend_endpoint" {
  value = module.frontend.website_endpoint
}
