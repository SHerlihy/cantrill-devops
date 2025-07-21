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

variable "server_id" {
    type = string
}

variable "domain_name" {
    type = string
}

resource "aws_eip" "server" {
  domain   = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = var.server_id
  allocation_id = aws_eip.server.id
}

resource "aws_s3_bucket" "failover" {
# bucket = "www.${var.domain_name}"
}

resource "aws_s3_bucket_public_access_block" "failover" {
  bucket = aws_s3_bucket.failover.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#resource "aws_s3_bucket_acl" "failover" {
#  bucket = aws_s3_bucket.failover.id
#  acl    = "public-read"
#}

resource "aws_s3_bucket_policy" "failover" {
  bucket = aws_s3_bucket.failover.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.failover.arn}/*"
      },
    ]
  })
}

locals {
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "gif"  = "image/gif"
  }
}

resource "aws_s3_object" "failover" {
  for_each = fileset("${path.module}/website", "**/*")

  bucket       = aws_s3_bucket.failover.id
  key          = each.value
  source       = "${path.module}/website/${each.value}"

  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")

#  acl = "public-read"
}

resource "aws_s3_bucket_website_configuration" "failover" {
  bucket = aws_s3_bucket.failover.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
