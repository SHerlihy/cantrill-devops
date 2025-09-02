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
  instance_sg      = "sg-07332c32592d24281"
  instance_profile = "arn:aws:iam::933142127213:instance-profile/A4LVPC-WordpressInstanceProfile-REQ3g5kwkuKD"
  lb_sg            = "sg-0b680c4bc28be5b90"
  lb_subnet        = "subnet-0169674b1b60b0805"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "prototype" {
  launch_template {
    id = aws_launch_template.prototype.id
  }

  tags = {
    Name = "proto"
  }
}

resource "aws_launch_template" "prototype" {
  credit_specification {
    cpu_credits = "standard"
  }
  iam_instance_profile {
    arn = local.instance_profile
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [local.instance_sg]
    subnet_id                   = local.lb_subnet
  }
  instance_type = "t2.micro"
  image_id      = data.aws_ami.amazon_linux_2023.id

    block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size = 30
      volume_type = "gp3"
    }
  }

  key_name = aws_key_pair.generated_key.key_name

  user_data = filebase64("${path.module}/user_data.sh")
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-ssh-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.this.private_key_pem
  filename = "${path.module}/ec2-key.pem"
  file_permission = "0400"
}

output "prototype_pub_ip" {
  value = aws_instance.prototype.public_ip
}
