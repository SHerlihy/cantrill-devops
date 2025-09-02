#!/bin/bash

cd ./resources/db
terraform destroy --auto-approve

cd ../efs
terraform destroy --auto-approve

cd ../..
cd ./service/lb
terraform destroy --auto-approve

cd ../..
cd ./service/app
terraform destroy --auto-approve
