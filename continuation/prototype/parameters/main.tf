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
  db_pass      = "4n1m4l54L1f3"
  db_root_pass = "4n1m4l54L1f3"
  db_user      = "a4lwordpressuser"
  db_name      = "a4lwordpressdb"
  db_endpoint  = "127.0.0.1"
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
