#!/bin/bash

cd ./resources
terraform destroy --auto-approve

cd ..
cd ./service/lb
terraform destroy --auto-approve

cd ../..
cd ./service/app
terraform destroy --auto-approve
