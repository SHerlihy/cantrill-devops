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
  username = "admin"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "catpics" {
  description = "catpics"
}

resource "aws_kms_key_policy" "catpics" {
  key_id = aws_kms_key.catpics.id
  policy = jsonencode({
    Id = "example"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Action   = "kms:*"
        Resource = "*"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_s3_bucket" "catpics" {
  bucket_prefix = "catpics"
}

resource "aws_s3_bucket_policy" "catpics" {
  bucket = aws_s3_bucket.catpics.id
  policy = data.aws_iam_policy_document.catpics.json
}

data "aws_iam_policy_document" "catpics" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.catpics.arn,
      "${aws_s3_bucket.catpics.arn}/*",
    ]
  }
}

resource "aws_s3_object" "s3_encrypt" {
  key                    = "sse-s3-dweez.jpg"
  bucket                 = aws_s3_bucket.catpics.id
  source                 = "${path.module}/object_encryption/sse-s3-dweez.jpg"
}

resource "aws_s3_object" "kms_encrypt" {
  key                    = "sse-kms-ginny.jpg"
  bucket                 = aws_s3_bucket.catpics.id
  source                 = "${path.module}/object_encryption/sse-kms-ginny.jpg"
  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.catpics.arn
}

data "aws_iam_policy_document" "no_kms" {
  statement {
    effect    = "Deny"
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "no_kms" {
  user = local.username
  policy = data.aws_iam_policy_document.no_kms.json
}

#add deny all kms to iam admin user

#
#
# locals {
#   mime_types = {
#     "html" = "text/html"
#     "css"  = "text/css"
#     "js"   = "application/javascript"
#     "png"  = "image/png"
#     "jpg"  = "image/jpeg"
#     "gif"  = "image/gif"
#   }
# }
#
# resource "aws_s3_object" "website" {
#   for_each = fileset("${path.module}/website", "**/*")
#
#   bucket = var.s3_id
#   key    = each.value
#   source = "${path.module}/website/${each.value}"
#
#   content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
# }
