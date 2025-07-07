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

data "aws_region" "current" {}

resource "aws_sns_topic" "updates" {
  name = "updates"
}

resource "aws_sns_topic_subscription" "updates_to_email" {
  topic_arn = aws_sns_topic.updates.arn
  protocol  = "email"
  endpoint  = "steven0herlihy+cantrill-general@gmail.com"
}

# resource "aws_sns_topic_subscription" "updates_to_gateway" {
#   topic_arn = aws_sns_topic.updates.arn
#   protocol  = "http"
#   endpoint  = aws_api_gateway_resource.sns.id
# }
#
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

resource "aws_iam_role" "gateway_sns" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "gateway_sns" {
  role = aws_iam_role.gateway_sns.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.updates.arn}"
    }
  ]
}
EOF
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
  http_method          = aws_api_gateway_method.sns_post.http_method
  integration_http_method = "POST"
  type                 = "AWS"
  uri = "arn:aws:apigateway:${data.aws_region.current.name}:sns:action/Publish"
  #" /path/${aws_sns_topic.updates.id}/"

  credentials = aws_iam_role.gateway_sns.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=Publish&TopicArn=${aws_sns_topic.updates.arn}&Message=$${util.urlEncode($input.body)}"
  }
  # uri = arn:aws:apigateway:{region}:{subdomain.service|service}:{path|action}/{service_api}
  # arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-west-1:123456789012:function:my-func/invocations
}

resource "aws_api_gateway_integration_response" "sns_post" {
  depends_on = [
    aws_api_gateway_integration.sns_post
  ]

  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.sns.id
  http_method = aws_api_gateway_method.sns_post.http_method
  status_code = "200"

  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200,
  "message": "Message sent to sns"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "sns_post_200" {
  depends_on = [
    aws_api_gateway_integration.sns_post
  ]

  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.sns.id
  http_method = aws_api_gateway_method.sns_post.http_method
  status_code = "200"
}
