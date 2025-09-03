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

resource "aws_ssm_parameter" "wp_db_name" {
    name = "/A4L/Wordpress/DBName"
    description = "Wordpress Database Name"
tier = "Standard"
type = "String"
data_type = "text"
value = var.db_name
}

resource "aws_ssm_parameter" "wp_db_user" {
    name = "/A4L/Wordpress/DBUser"
    description = "Wordpress Database User"
tier = "Standard"
type = "String"
data_type = "text"
value = var.db_user
}

resource "aws_ssm_parameter" "wp_db_root_password" {
    name = "/A4L/Wordpress/DBRootPassword"
    description = "Wordpress DBRoot Password"
tier = "Standard"
type = "SecureString"

key_id = "alias/aws/ssm"

value = var.db_password
}

resource "aws_ssm_parameter" "wp_db_password" {
    name = "/A4L/Wordpress/DBPassword"
    description = "Wordpress DB Password"
tier = "Standard"
type = "SecureString"

key_id = "alias/aws/ssm"

value = var.db_password
}

resource "aws_ssm_parameter" "wp_db_endpoint" {
    name = "/A4L/Wordpress/DBEndpoint"
    description = "Wordpress Endpoint Name"
tier = "Standard"
type = "String"
data_type = "text"
value = aws_db_instance.db.address
}

resource "aws_db_subnet_group" "db" {
  subnet_ids = var.subnets
}

resource "aws_db_instance" "db" {
  engine               = "mysql"
  engine_version       = "8.0.43"
  db_subnet_group_name = aws_db_subnet_group.db.id

  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  instance_class       = "db.t3.micro"

network_type = "IPV4"

vpc_security_group_ids = [var.db_sg]

availability_zone = "us-east-1a"

  allocated_storage    = 10
  skip_final_snapshot = true

  parameter_group_name = aws_db_parameter_group.skip_name_resolve.name
}

resource "aws_db_parameter_group" "skip_name_resolve" {
  family = "mysql8.0"

  parameter {
    name  = "skip_name_resolve"
    value = 1
    apply_method="pending-reboot"
  }
}
