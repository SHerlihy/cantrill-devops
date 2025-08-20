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

variable "subnets" {
    type = set(string)
}

locals {
db_name = "a4lwordpressdb"
db_user = "a4lwordpressuser"
db_password = "4n1m4154L1f3"

db_sg = "sg-06cf4aa0df76e307b"
}

resource "aws_ssm_parameter" "wp_db_name" {
    name = "/A4L/Wordpress/DBName"
    description = "Wordpress Database Name"
tier = "Standard"
type = "String"
data_type = "text"
value = local.db_name
}

resource "aws_ssm_parameter" "wp_db_user" {
    name = "/A4L/Wordpress/DBUser"
    description = "Wordpress Database User"
tier = "Standard"
type = "String"
data_type = "text"
value = local.db_user
}

resource "aws_ssm_parameter" "wp_db_password" {
    name = "/A4L/Wordpress/DBPassword"
    description = "Wordpress DBRoot Password"
tier = "Standard"
type = "SecureString"

key_id = "alias/aws/ssm"

value = local.db_password
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

  db_name              = local.db_name
  username             = local.db_user
  password             = local.db_password
  instance_class       = "db.t3.micro"

network_type = "IPV4"

vpc_security_group_ids = [local.db_sg]

availability_zone = "us-east-1a"

  allocated_storage    = 10
  skip_final_snapshot = true
}
