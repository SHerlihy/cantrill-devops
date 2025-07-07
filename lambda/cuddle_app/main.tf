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

resource "aws_ses_email_identity" "sender" {
  email = "steven0herlihy+cuddle-app-sender@gmail.com"
}

resource "aws_ses_email_identity" "receiver" {
  email = "steven0herlihy+cuddle-app-receiver@gmail.com"
}
