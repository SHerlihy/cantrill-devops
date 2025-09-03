#!/bin/bash

cd ./resources/db
terraform init
terraform apply --auto-approve
cd ../..

cd ./resources/efs
terraform init
terraform apply --auto-approve
cd ../..

cd ./prototype/parameters
terraform init
terraform apply --auto-approve
cd ../..

cd ./prototype
terraform init
terraform apply -var-file="../shared/frontend.tfvars" --auto-approve
cd ..

cd ./service/server
terraform init
terraform apply -var-file="../../shared/frontend.tfvars" --auto-approve
terraform output >> ./output.tfvars
cd ../..

cd ./service/scaler
terraform init
terraform apply -var-file="./terraform.tfvars" -var-file="../../shared/frontend.tfvars" -var-file="../server/output.tfvars" --auto-approve
cd ../..
