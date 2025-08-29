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

locals {
  lb_name          = "A4LWORDPRESSALB"
  lb_sg            = "sg-0b680c4bc28be5b90"
  lb_subnets       = ["subnet-0169674b1b60b0805", "subnet-08fef8aaa801ca34d", "subnet-08a7fcf33aa5596d4"]
}

resource "aws_ssm_parameter" "elb_dns" {
  name        = "/A4L/Wordpress/ALBDNSNAME"
  description = "DNS Name of the Application Load Balancer for wordpress"
  tier        = "Standard"
  type        = "String"
  data_type   = "text"
  value       = aws_lb.lb.dns_name
}

resource "aws_lb" "lb" {
  name = local.lb_name

  subnets = local.lb_subnets

  security_groups    = [local.lb_sg]
  load_balancer_type = "application"
}

output "lb_arn" {
  value = aws_lb.lb.arn
}
