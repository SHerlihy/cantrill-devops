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

variable "s3_id" {
  type = string
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

resource "aws_s3_object" "website" {
  for_each = fileset("${path.module}/website", "**/*")

  bucket = var.s3_id
  key    = each.value
  source = "${path.module}/website/${each.value}"

  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = var.s3_id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

output "website_domain" {
    value                   = aws_s3_bucket_website_configuration.website.website_domain
}

