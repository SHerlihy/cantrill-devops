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

variable "server_id" {
    type = string
}

variable "domain_name" {
    type = string
}

variable "zone_id" {
    type = string
}

resource "aws_eip" "server" {
  domain   = "vpc"
}

module "failover" {
  source = "./failover"
  domain_name = var.domain_name
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = var.server_id
  allocation_id = aws_eip.server.id
}

resource "aws_route53_health_check" "eip" {
  ip_address              = aws_eip.server.public_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/index.html"
  failure_threshold = "5"
  request_interval  = "10"
}

resource "aws_route53_record" "a4l" {
  health_check_id = aws_route53_health_check.eip.id

  zone_id = var.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.server.public_ip]

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "a4l"
}

resource "aws_route53_record" "failover" {
  #  health_check_id = aws_route53_health_check.eip.id

  zone_id = var.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name = module.failover.domain
    zone_id = module.failover.zone_id
    evaluate_target_health = false
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "failover"
}
