#!/bin/bash
EFS_MOUNT_POINT="/mnt/efs"
EFS_DNS="fs-0eb5f3393d00e4ae9.efs.us-east-1.amazonaws.com"

apt-get update -y
apt-get install -y nfs-common

mkdir -p ${EFS_MOUNT_POINT}
# file-system-id.efs.us-east-1.amazonaws.com
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_DNS}:/ ${EFS_MOUNT_POINT}
echo "${EFS_DNS}:/ ${EFS_MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

chown ubuntu:ubuntu ${EFS_MOUNT_POINT}
# #
# # cd ~/efs-mount-point
# # sudo chmod go+rw .
# # touch test-file.txt
# #
# sudo apt update -y
# sudo apt install apache2 -y
# sudo systemctl start apache2
# echo "Deploy a web server on aws" | sudo tee /var/www/html/index.html
