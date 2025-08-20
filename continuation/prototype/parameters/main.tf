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
