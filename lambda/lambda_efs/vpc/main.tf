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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "pub_to_net" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_route_table_association" "pub_to_net" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub_to_net.id
}

resource "aws_eip" "public" {
  domain = "vpc"
  depends_on                = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "to_pub" {
  allocation_id = aws_eip.public.id
  subnet_id                          = aws_subnet.public.id
}

resource "aws_route_table" "pvt_to_pub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.to_pub.id
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_route_table_association" "pvt_to_pub" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.pvt_to_pub.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet" {
value = aws_subnet.public.id
}

output "private_subnet" {
    value = aws_subnet.private.id
}
