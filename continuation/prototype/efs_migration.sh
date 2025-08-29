sudo bash
cd

dnf -y install amazon-efs-utils

cd /var/www/html
mv wp-content/ /tmp
mkdir wp-content
EFSFSID=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/EFSFSID --query Parameters[0].Value)
EFSFSID=`echo $EFSFSID | sed -e 's/^"//' -e 's/"$//'`

echo -e "$EFSFSID:/ /var/www/html/wp-content efs _netdev,tls,iam 0 0" >> /etc/fstab
mount -a -t efs defaults
mv /tmp/wp-content/* /var/www/html/wp-content/
chown -R ec2-user:apache /var/www/
