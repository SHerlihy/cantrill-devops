#!/bin/bash

PROTO_IP=$1

ssh ec2-user@$PROTO_IP "bash -s" < ./db_migration.sh
ssh ec2-user@$PROTO_IP "bash -s" < ./efs_migration.sh
