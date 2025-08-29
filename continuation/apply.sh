#!/bin/bash

cd ./resources
terraform apply --auto-approve

cd ..
cd ./service/lb
terraform apply --auto-approve
terraform output > ../app/terraform.tfvars

cd ../..
cd ./service/app
terraform apply --auto-approve
