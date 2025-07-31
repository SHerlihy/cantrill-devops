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

variable "bucket" {
    type = string
}

variable "key" {
    type = string
}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket
}

resource "aws_s3_object" "example_object" {
  bucket = aws_s3_bucket.example.id
  key    = var.key
  source = "${path.module}/nohair.jpg"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}
