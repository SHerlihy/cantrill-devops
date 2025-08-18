#!/bin/bash -xe

# DBPassword=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBPassword --with-decryption --query Parameters[0].Value)
# DBPassword=`echo $DBPassword | sed -e 's/^"//' -e 's/"$//'`
#
# DBRootPassword=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBRootPassword --with-decryption --query Parameters[0].Value)
# DBRootPassword=`echo $DBRootPassword | sed -e 's/^"//' -e 's/"$//'`
#
# DBUser=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBUser --query Parameters[0].Value)
# DBUser=`echo $DBUser | sed -e 's/^"//' -e 's/"$//'`
#
# DBName=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBName --query Parameters[0].Value)
# DBName=`echo $DBName | sed -e 's/^"//' -e 's/"$//'`
#
# DBEndpoint=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/DBEndpoint --query Parameters[0].Value)
# DBEndpoint=`echo $DBEndpoint | sed -e 's/^"//' -e 's/"$//'`
#
# EFSFSID=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/EFSFSID --query Parameters[0].Value)
# EFSFSID=`echo $EFSFSID | sed -e 's/^"//' -e 's/"$//'`
#
# ALBDNSNAME=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/ALBDNSNAME --query Parameters[0].Value)
# ALBDNSNAME=`echo $ALBDNSNAME | sed -e 's/^"//' -e 's/"$//'`

dnf -y update

dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel stress -y amazon-efs-utils

systemctl enable httpd
systemctl start httpd

# mkdir -p /var/www/html/wp-content
# chown -R ec2-user:apache /var/www/
# echo -e "$EFSFSID:/ /var/www/html/wp-content efs _netdev,tls,iam 0 0" >> /etc/fstab
# mount -a -t efs defaults
#
# mysqladmin -u root password $DBRootPassword
#
# wget http://wordpress.org/latest.tar.gz -P /var/www/html
# cd /var/www/html
# tar -zxvf latest.tar.gz
# cp -rvf wordpress/* .
# rm -R wordpress
# rm latest.tar.gz
#
# sudo cp ./wp-config-sample.php ./wp-config.php
# sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
# sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
# sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
# sed -i "s/'localhost'/'$DBEndpoint'/g" wp-config.php
#
# usermod -a -G apache ec2-user   
# chown -R ec2-user:apache /var/www
# chmod 2775 /var/www
# find /var/www -type d -exec chmod 2775 {} \;
# find /var/www -type f -exec chmod 0664 {} \;
#
# cat >> /home/ec2-user/update_wp_ip.sh<< 'EOF'
# #!/bin/bash
# source <(php -r 'require("/var/www/html/wp-config.php"); echo("DB_NAME=".DB_NAME."; DB_USER=".DB_USER."; DB_PASSWORD=".DB_PASSWORD."; DB_HOST=".DB_HOST); ')
# SQL_COMMAND="mysql -u $DB_USER -h $DB_HOST -p$DB_PASSWORD $DB_NAME -e"
# OLD_URL=$(mysql -u $DB_USER -h $DB_HOST -p$DB_PASSWORD $DB_NAME -e 'select option_value from wp_options where option_name = "siteurl";' | grep http)
#
# ALBDNSNAME=$(aws ssm get-parameters --region us-east-1 --names /A4L/Wordpress/ALBDNSNAME --query Parameters[0].Value)
# ALBDNSNAME=`echo $ALBDNSNAME | sed -e 's/^"//' -e 's/"$//'`
#
# $SQL_COMMAND "UPDATE wp_options SET option_value = replace(option_value, '$OLD_URL', 'http://$ALBDNSNAME') WHERE option_name = 'home' OR option_name = 'siteurl';"
# $SQL_COMMAND "UPDATE wp_posts SET guid = replace(guid, '$OLD_URL','http://$ALBDNSNAME');"
# $SQL_COMMAND "UPDATE wp_posts SET post_content = replace(post_content, '$OLD_URL', 'http://$ALBDNSNAME');"
# $SQL_COMMAND "UPDATE wp_postmeta SET meta_value = replace(meta_value,'$OLD_URL','http://$ALBDNSNAME');"
# EOF
#
# chmod 755 /home/ec2-user/update_wp_ip.sh
# echo "/home/ec2-user/update_wp_ip.sh" >> /etc/rc.local
# /home/ec2-user/update_wp_ip.sh
