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

resource "aws_iam_user" "sally" {
  name = "sally"
}

data "aws_iam_policy" "change_pass" {
  arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_user_policy_attachment" "change_pass" {
  user       = aws_iam_user.sally.name
  policy_arn = data.aws_iam_policy.change_pass.arn
}

resource "aws_iam_user_login_profile" "sally" {
  user = aws_iam_user.sally.name
}

resource "aws_iam_group" "anti_cats" {
  name = "anti_cats"
}

resource "aws_iam_group_membership" "anti_cats" {
  name = "anti_cats"

  users = [
    aws_iam_user.sally.name,
  ]

  group = aws_iam_group.anti_cats.name
}

resource "aws_s3_bucket" "cat" {
  bucket_prefix = "cat"
}
resource "aws_s3_bucket" "dog" {
  bucket_prefix = "dog"
}
resource "aws_s3_bucket" "animal" {
  bucket_prefix = "animal"
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.cat.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "s3" {
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_group_policy_attachment" "s3" {
  group = aws_iam_group.anti_cats.name
  policy_arn = aws_iam_policy.s3.arn
}

output "password" {
sensitive = true
  value = aws_iam_user_login_profile.sally.password
}
