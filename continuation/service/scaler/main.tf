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

resource "aws_ssm_parameter" "elb_dns" {
  name        = "/A4L/Wordpress/ALBDNSNAME"
  description = "DNS Name of the Application Load Balancer for wordpress"
  tier        = "Standard"
  type        = "String"
  data_type   = "text"
  value       = aws_lb.lb.dns_name
}

resource "aws_lb" "lb" {
  name = var.lb_name

  subnets = var.lb_subnets

  security_groups    = [var.lb_sg]
  load_balancer_type = "application"
}

resource "aws_lb_target_group" "root" {
  name             = var.tg_name
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  vpc_id           = var.vpc

  health_check {
    path     = "/"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = var.lb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.root.arn
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                = var.asg_name
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.lb_subnets

  launch_template {
    id      = var.launch_id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.root.arn]

  health_check_type     = "ELB"
  protect_from_scale_in = false
}
