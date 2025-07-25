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
  planets_db = "s3://osm-pds/planet/"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "query_results" {
  bucket_prefix = "query-results"
}

resource "aws_s3_bucket_public_access_block" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
                Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.query_results.arn}/*"
      },
    ]
  })
}

resource "aws_athena_database" "planets" {
  name   = "planets"
  bucket = aws_s3_bucket.query_results.id
}

resource "aws_athena_workgroup" "planets" {
  name = "planets"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.id}/"
      expected_bucket_owner = data.aws_caller_identity.current.account_id
    }
  }
}

resource "aws_athena_named_query" "create_planet_table" {
  name     = "create_planet_table"
  workgroup = aws_athena_workgroup.planets.id
  database = aws_athena_database.planets.name
  query    = <<-EOT
CREATE EXTERNAL TABLE planet (
  id BIGINT,
  type STRING,
  tags MAP<STRING,STRING>,
  lat DECIMAL(9,7),
  lon DECIMAL(10,7),
  nds ARRAY<STRUCT<ref: BIGINT>>,
  members ARRAY<STRUCT<type: STRING, ref: BIGINT, role: STRING>>,
  changeset BIGINT,
  timestamp TIMESTAMP,
  uid BIGINT,
  user STRING,
  version BIGINT
)
STORED AS ORCFILE
LOCATION 's3://osm-pds/planet/';
EOT
}

resource "aws_athena_named_query" "first_100" {
  name     = "create_planet_table"
  workgroup = aws_athena_workgroup.planets.id
  database = aws_athena_database.planets.name
  query    = "Select * from planet LIMIT 100;"
}

resource "aws_athena_named_query" "specific_query" {
  name     = "create_planet_table"
  workgroup = aws_athena_workgroup.planets.id
  database = aws_athena_database.planets.name
  query    = <<-EOT
SELECT * from planet
WHERE type = 'node'
  AND tags['amenity'] IN ('veterinary')
  AND lat BETWEEN -27.8 AND -27.3
  AND lon BETWEEN 152.2 AND 153.5;
EOT
}
