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
  lb_subnet        = "subnet-0169674b1b60b0805"
  lb_subnets       = ["subnet-0169674b1b60b0805", "subnet-08fef8aaa801ca34d", "subnet-08a7fcf33aa5596d4"]
  lb_sg            = "sg-0b680c4bc28be5b90"
  instance_sg = "sg-07332c32592d24281"
  tg_name          = "A4LWORDPRESSALBTG"
  lb_name          = "A4LWORDPRESSALB"
  asg_name         = "A4LWORDPRESSASG"
  vpc              = "vpc-0172f519fb6d14516"
  instance_profile = "arn:aws:iam::933142127213:instance-profile/A4LVPC-WordpressInstanceProfile-REQ3g5kwkuKD"
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

resource "aws_lb_target_group" "root" {
  name             = local.tg_name
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  vpc_id           = local.vpc

  health_check {
    path     = "/"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.root.arn
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                = local.asg_name
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = local.lb_subnets

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.root.arn]

  health_check_type     = "ELB"
  protect_from_scale_in = false
}

# resource "aws_autoscaling_attachment" "frontend" {
#   autoscaling_group_name = aws_autoscaling_group.frontend.id
#   lb_target_group_arn                    = aws_lb_target_group.root.id
# }

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "example" {
  credit_specification {
    cpu_credits = "standard"
  }
  iam_instance_profile {
    arn = local.instance_profile
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [local.instance_sg]
  }
  instance_type = "t2.micro"
  image_id      = data.aws_ami.amazon_linux_2.id

  user_data = filebase64("${path.module}/example.sh")
}

resource "aws_launch_template" "frontend" {
  credit_specification {
    cpu_credits = "standard"
  }
  iam_instance_profile {
    arn = local.instance_profile
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [local.instance_sg]
  }
  instance_type = "t2.micro"
  image_id      = data.aws_ami.amazon_linux_2.id

  user_data = filebase64("${path.module}/user_data.sh")
}
