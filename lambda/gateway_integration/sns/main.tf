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

variable "rest_api_id" {
    type = string
}

variable "parent_id" {
    type = string
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "updates" {
  name = "updates"
}

resource "aws_sns_topic_subscription" "updates_to_email" {
  topic_arn = aws_sns_topic.updates.arn
  protocol  = "email"
  endpoint  = "steven0herlihy+cantrill-general@gmail.com"
}

resource "aws_sns_topic_subscription" "updates_to_gateway" {
  topic_arn = aws_sns_topic.updates.arn
  protocol  = "http"
  endpoint  = aws_api_gateway_resource.sns.id
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.updates.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.updates.arn,
    ]
  }
}

resource "aws_api_gateway_resource" "sns" {
  rest_api_id   = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "sns"
}

resource "aws_api_gateway_method" "sns_post" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.sns.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sns_post" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.sns.id
  http_method          = aws_api_gateway_method.sns_get.http_method
  type                 = "AWS"
  uri = "arn:aws:apigateway:${region}:sns:post/${aws_sns_topic_subscription.updates_to_sns.id}"
  # uri = arn:aws:apigateway:{region}:{subdomain.service|service}:{path|action}/{service_api}
  # arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-west-1:123456789012:function:my-func/invocations
}

resource "aws_api_gateway_method_response" "sns_post_200" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.sns.id
  http_method = aws_api_gateway_method.sns_post.http_method
  status_code = "200"
}

