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

variable "api_url" {
  type = string
}

resource "aws_s3_bucket" "cuddle" {
  force_destroy = true
  bucket_prefix = "cuddle"
}

resource "aws_s3_bucket_ownership_controls" "cuddle" {
  bucket = aws_s3_bucket.cuddle.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cuddle" {
  bucket = aws_s3_bucket.cuddle.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "cuddle" {
  depends_on = [
    aws_s3_bucket_ownership_controls.cuddle,
    aws_s3_bucket_public_access_block.cuddle,
  ]

  bucket = aws_s3_bucket.cuddle.id
  acl    = "public-read"
}

data "aws_iam_policy_document" "cuddle" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      aws_s3_bucket.cuddle.arn,
      "${aws_s3_bucket.cuddle.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cuddle" {
  bucket = aws_s3_bucket_public_access_block.cuddle.id

  policy = data.aws_iam_policy_document.cuddle.json
}

locals {
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
  }
}

locals {
  all_files      = fileset("${path.module}/serverless_frontend", "**/*")
  template_files = toset(["serverless.js.tpl"])
  static_files   = setsubtract(local.all_files, local.template_files)
}

resource "aws_s3_object" "cuddle_static" {
  for_each = local.static_files

  bucket       = aws_s3_bucket.cuddle.id
  key          = each.value
  source       = "${path.module}/serverless_frontend/${each.value}"
  etag         = filemd5("${path.module}/serverless_frontend/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), "binary/octet-stream")

  depends_on = [aws_s3_bucket_policy.cuddle]
}

resource "aws_s3_object" "cuddle_js" {
  bucket = aws_s3_bucket.cuddle.id
  key    = "serverless.js"
  content = templatefile("${path.module}/serverless_frontend/serverless.js.tpl", {
    API_URL = var.api_url
  })
  etag         = filemd5("${path.module}/serverless_frontend/serverless.js.tpl")
  content_type = "application/javascript"

  depends_on = [aws_s3_bucket_policy.cuddle]
}

resource "aws_s3_bucket_website_configuration" "cuddle" {
  depends_on = [
    aws_s3_bucket_policy.cuddle
  ]

  bucket = aws_s3_bucket.cuddle.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.cuddle.website_endpoint
}
