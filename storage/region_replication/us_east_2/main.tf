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
  region  = "us-east-2"
}

resource "aws_s3_bucket" "destination" {
  bucket_prefix = "destination"
}

resource "aws_s3_bucket_public_access_block" "destination" {
  bucket = aws_s3_bucket.destination.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "destination" {
  bucket = aws_s3_bucket.destination.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.destination.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "id" {
    value = aws_s3_bucket.destination.id
}

output "arn" {
    value = aws_s3_bucket.destination.arn
}

output "versioning" {
    value = aws_s3_bucket_versioning.destination
}
