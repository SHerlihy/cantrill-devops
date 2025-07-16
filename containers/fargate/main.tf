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
  coc_name = "containerofcats"
}

data "aws_availability_zones" "available" {
  all_availability_zones = true
  state                  = "available"
}

resource "aws_default_vpc" "default" {}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  vpc_id      = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ecs_cluster" "coc" {
  name = local.coc_name
}

resource "aws_ecs_service" "coc" {
  name                 = local.coc_name
  cluster              = aws_ecs_cluster.coc.id
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups = [aws_security_group.allow_http.id]
  }

  task_definition = aws_ecs_task_definition.coc.arn
}

resource "aws_ecs_task_definition" "coc" {
  family                   = local.coc_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  container_definitions = jsonencode([
    {
      name      = local.coc_name
      image     = "docker.io/acantril/containerofcats"
      memory    = 1024
      essential = true,
      portMappings = [
        {
          name          = local.coc_name
          appProtocol   = "http"
          protocol      = "tcp"
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}
