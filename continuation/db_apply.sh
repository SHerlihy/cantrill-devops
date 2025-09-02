#!/bin/bash

cd ./resources/db
terraform init
terraform apply --auto-approve
cd ../..

cd ./resources/efs
terraform init
terraform apply --auto-approve
cd ../..

cd ./service/lb
terraform apply --auto-approve
terraform output > ../app/terraform.tfvars
cd ../..

cd ./service/app
terraform apply --auto-approve
cd ../..

cd ./prototype
terraform apply --auto-approve
cd ..
