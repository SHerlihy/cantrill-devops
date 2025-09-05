#!/bin/bash

ACCESS=13-223-60-7

ssh -i "./ec2-key.pem" ec2-user@ec2-$ACCESS.compute-1.amazonaws.com "bash -s" < ./db_migration.sh
ssh -i "./ec2-key.pem" ec2-user@ec2-$ACCESS.compute-1.amazonaws.com "bash -s" < ./efs_migration.sh
