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

# DBPassword=$(aws ssm get-parameters --region us-east-1 --names /proto/A4L/Wordpress/DBPassword --with-decryption --query Parameters[0].Value)
# DBPassword=`echo $DBPassword | sed -e 's/^"//' -e 's/"$//'`
# 
# DBRootPassword=$(aws ssm get-parameters --region us-east-1 --names /proto/A4L/Wordpress/DBRootPassword --with-decryption --query Parameters[0].Value)
# DBRootPassword=`echo $DBRootPassword | sed -e 's/^"//' -e 's/"$//'`
# 
# DBUser=$(aws ssm get-parameters --region us-east-1 --names /proto/A4L/Wordpress/DBUser --query Parameters[0].Value)
# DBUser=`echo $DBUser | sed -e 's/^"//' -e 's/"$//'`
# 
# DBName=$(aws ssm get-parameters --region us-east-1 --names /proto/A4L/Wordpress/DBName --query Parameters[0].Value)
# DBName=`echo $DBName | sed -e 's/^"//' -e 's/"$//'`
# 
# DBEndpoint=$(aws ssm get-parameters --region us-east-1 --names /proto/A4L/Wordpress/DBEndpoint --query Parameters[0].Value)
# DBEndpoint=`echo $DBEndpoint | sed -e 's/^"//' -e 's/"$//'`


locals {
  lb_subnet        = "subnet-0169674b1b60b0805"
  lb_subnets       = ["subnet-0169674b1b60b0805", "subnet-08fef8aaa801ca34d", "subnet-08a7fcf33aa5596d4"]
  lb_sg            = "sg-0b680c4bc28be5b90"
  instance_sg      = "sg-07332c32592d24281"
  tg_name          = "A4LWORDPRESSALBTG"
  lb_name          = "A4LWORDPRESSALB"
  asg_name         = "A4LWORDPRESSASG"
  vpc              = "vpc-0172f519fb6d14516"
  instance_profile = "arn:aws:iam::933142127213:instance-profile/A4LVPC-WordpressInstanceProfile-REQ3g5kwkuKD"

  db_pass      = "4n1m4l54L1f3"
  db_root_pass = "4n1m4l54L1f3"
  db_user      = "a4lwordpressuser"
  db_name      = "a4lwordpressdb"
  db_endpoint  = "localhost"
}

resource "aws_ssm_parameter" "proto_db_pass" {
  name      = "/proto/A4L/Wordpress/DBPassword"
  tier      = "Standard"
  type      = "String"
  data_type = "text"
  value     = local.db_pass
}
resource "aws_ssm_parameter" "proto_db_root_pass" {
  name      = "/proto/A4L/Wordpress/DBRootPassword"
  tier      = "Standard"
  type      = "SecureString"
  data_type = "text"
  value     = local.db_root_pass
}
resource "aws_ssm_parameter" "proto_db_user" {
  name      = "/proto/A4L/Wordpress/DBUser"
  tier      = "Standard"
  type      = "String"
  data_type = "text"
  value     = local.db_user
}
resource "aws_ssm_parameter" "proto_db_name" {
  name      = "/proto/A4L/Wordpress/DBName"
  tier      = "Standard"
  type      = "String"
  data_type = "text"
  value     = local.db_name
}
resource "aws_ssm_parameter" "proto_db_endpoint" {
  name      = "/proto/A4L/Wordpress/DBEndpoint"
  tier      = "Standard"
  type      = "String"
  data_type = "text"
  value     = local.db_endpoint
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
      volume_size = 20
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
