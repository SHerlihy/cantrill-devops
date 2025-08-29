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
  type = list(string)
}

locals {
    efs_name = "A4L-WORDPRESS-CONTENT"
    efs_sg = "sg-065cbcc53665e077d"
}

resource "aws_ssm_parameter" "efs_id" {
    name = "/A4L/Wordpress/EFSFSID"
    description = "File System ID for Wordpress Content (wp-content)"
tier = "Standard"
type = "String"
data_type = "text"
value = aws_efs_file_system.efs.dns_name
}

resource "aws_efs_file_system" "efs" {
encrypted = false
performance_mode = "generalPurpose"
throughput_mode = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "subnets" {
    for_each = toset(var.subnets)

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.key
  security_groups = [local.efs_sg]
}
