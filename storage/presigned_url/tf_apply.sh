#!/bin/bash
BUCKET="unique4bqt42tnb"
KEY="key"

terraform apply -var="bucket=${BUCKET}" -var="key=${KEY}" --auto-approve
aws s3 presign s3://${BUCKET}/${KEY} --expires-in 604800 --profile cantrill-general-admin
