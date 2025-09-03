#!/bin/bash

cd ./resources/db
terraform destroy --auto-approve
cd ../..

cd ./resources/efs
terraform destroy --auto-approve
cd ../..

cd ./prototype/parameters
terraform destroy --auto-approve
cd ../..

cd ./prototype
terraform destroy -var-file="./terraform.tfvars" -var-file="../shared/frontend.tfvars" --auto-approve
cd ..

cd ./service/server
terraform destroy -var-file="./terraform.tfvars" -var-file="../../shared/frontend.tfvars" --auto-approve
cd ../..

cd ./service/scaler
terraform destroy -var-file="./terraform.tfvars" -var-file="../../shared/frontend.tfvars" -var-file="../server/output.tfvars" --auto-approve
cd ../..
