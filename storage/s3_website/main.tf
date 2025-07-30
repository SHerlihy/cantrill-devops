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

variable "domain_name" {
  type = string
}

variable "zone_id" {
  type = string
}

module "s3" {
  source = "./create_s3"

  domain_name = var.domain_name
}

module "upload" {
  source = "./upload"

  s3_id = module.s3.id
#
#   depends_on = [
#     module.s3
#   ]
}

resource "aws_route53_record" "website" {
  zone_id = var.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.upload.website_domain
    zone_id                = module.s3.hosted_zone_id
    evaluate_target_health = false
  }

  # set_identifier = "website"
}
