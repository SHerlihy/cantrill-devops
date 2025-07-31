#!/bin/bash
BUCKET="unique4bqt42tnb"
KEY="key"

terraform destroy -var="bucket=${BUCKET}" -var="key=${KEY}" --auto-approve
