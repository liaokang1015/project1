#!/bin/bash
#install edusoho
Mysql_Pass=123

#update
#yum update

#epel
yum -y install epel-release

#env
yum -y install bash-completion vim wget
systemctl restart firewalld
systemctl enable firewalld

setenforce 0

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

#LAMP
yum -y install httpd
yum -y install \
php php-cli \
php-curl \
php-fpm \
php-intl \
php-mcrypt \
php-mysql \
php-gd \
php-mbstring \
php-xml \
php-dom

yum -y install mariadb-server mariadb
yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/m/mod_xsendfile-0.12-10.el7.x86_64.rpm

#apache
rm -rf /etc/httpd/conf.d/welcome.conf
#sed -ri 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
systemctl enable httpd

#mysql
systemctl start mariadb
systemctl enable mariadb

mysqladmin -uroot password "$Mysql_Pass"
mysql -uroot -p"$Mysql_Pass" -e "create database edusoho"

#php
sed -ri 's/post_max_size = 8M/post_max_size = 1024M/' /etc/php.ini
sed -ri 's/memory_limit = 128M/memory_limit = 1024M/' /etc/php.ini
sed -ri 's/upload_max_filesize = 2M/upload_max_filesize = 1024M/' /etc/php.ini
sed -ri 's#;date.timezone =#date.timezone = Asia/ShangHai#' /etc/php.ini
systemctl start php-fpm
systemctl enable php-fpm

#edusoho
wget http://download.edusoho.com/edusoho-7.5.12.tar.gz
tar xf edusoho-7.5.12.tar.gz
cp -rf edusoho /var/www/
chown -R apache.apache /var/www/edusoho/

rm -rf /var/www/html/index.html
sed -ri 's#DocumentRoot "/var/www/html"#DocumentRoot "/var/www/edusoho/web"#' /etc/httpd/conf/httpd.conf 
cat >>/etc/httpd/conf/httpd.conf <<EOF
<Directory "/var/www/edusoho/web">
AllowOverride All
Require all granted
</Directory>
EOF

systemctl restart httpd
systemctl restart php-fpm