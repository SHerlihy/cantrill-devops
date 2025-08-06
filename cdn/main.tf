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
  zone_id = "Z08305432FROM0MKA1SMO"
    public_domain = "cantrilldevops.click"
  s3_id = "cfands3-top10cats-hpjnq04wpoky"
  s3_origin_id = "arn:aws:s3:::cfands3-top10cats-hpjnq04wpoky"
}

locals {
    domain_name = "${local.s3_id}.s3.us-east-1.amazonaws.com"
  }

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = local.domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  enabled             = true
  is_ipv6_enabled     = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = "allow-all"

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  price_class = "PriceClass_All"

    default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }


  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
  }

  aliases = [local.public_domain]
}

resource "aws_s3_object" "merlin" {
  bucket = local.s3_id
  key    = "img/merlin.jpg"
  source = "${path.module}/merlin.jpg"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = local.public_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 5
  type            = each.value.type
  zone_id         = local.zone_id
}

resource "aws_route53_record" "website" {
  zone_id = local.zone_id
  name    = local.public_domain
  type    = "A"

  alias {
  name = aws_cloudfront_distribution.s3_distribution.domain_name
  zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
  evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = local.s3_id
  policy = data.aws_iam_policy_document.cloudfront_access.json
}

data "aws_iam_policy_document" "cloudfront_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      local.s3_origin_id,
      "${local.s3_origin_id}/*",
    ]

    
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.s3_distribution.arn
      ]
    }
  }
}
