#!/bin/sh

terraform apply -target="data.aws_subnets.default" --auto-approve
terraform apply --auto-approve
