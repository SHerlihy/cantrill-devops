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

# variable "sg" {
#     type = "string"
# }
#
# variable "instance_profile" {
#     type = "string"
# }
#
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

# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners      = ["amazon"]
#
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-ebs"]
#   }
#
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }
#
# resource "aws_instance" "wp_man" {
# name = "Wordpress Manual"
#   ami           = data.aws_ami.amazon-linux_2.id
#   instance_type = "t3.micro"
#   subnet_id     = var.subnet
#
# associate_public_ip_address = true
#
# security_groups = [
#     var.sg
# ]
#
# iam_instance_profile = var.instance_profile
#
#   credit_specification {
#     cpu_credits = "unlimited"
#   }
#
#     user_data = <<EOF
#
# #!/bin/bash
#
# sudo dnf -y install amazon-efs-utils
#
# cd /var/www/html
# sudo mv wp-content/ /tmp
# sudo mkdir wp-content
#
# EFSFSID=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/EFSFSID --query Parameters[0].Value)
# EFSFSID=`echo $EFSFSID | sed -e 's/^"//' -e 's/"$//'`
#
# echo -e "$EFSFSID:/ /var/www/html/wp-content efs _netdev,tls,iam 0 0" >> /etc/fstab
# mount -a -t efs defaults
#
# mv /tmp/wp-content/* /var/www/html/wp-content/
# chown -R ec2-user:apache /var/www/
#
# reboot
#
# EOF
# }
