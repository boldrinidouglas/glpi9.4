#!/bin/bash
echo "-------------------------------------------------------------------------------------"
echo "---------------------------------CentOS-8 and GLPI-9.4-------------------------------"
echo "-------------------------------------------------------------------------------------"

echo "Declaring Local Environment Variables"
set 
glpiversion='9.4'
phpversion='7.4' 
db='glpi'
pswd='glpipass'
userdb='glpi'
srv='localhost'
glpiacesso="192.168.1.10"

echo "Step 1: Install MariaDB and configuring mariadb"
sudo dnf -y update
sudo dnf module install mariadb -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "Step 2: Config MariaDB"
mysql -u root <<-EOF
DROP USER 'root'@'localhost';
CREATE USER 'root'@'%' IDENTIFIED BY 'glpipass';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "Step 3: Acessando e criandos o Banco de Dados"
mysql --user=root --password=glpipass --execute="CREATE DATABASE IF NOT EXISTS $db";
mysql --user=root --password=glpipass --execute="CREATE USER $userdb@$srv IDENTIFIED BY '$pswd'";
mysql --user=root --password=glpipass --execute="GRANT USAGE ON *.* TO $userdb@$srv IDENTIFIED BY '$pswd'";
mysql --user=root --password=glpipass --execute="GRANT ALL PRIVILEGES ON $db.* TO $userdb@$srv";
mysql --user=root --password=glpipass --execute="FLUSH PRIVILEGES";

echo "Step 4: Add Remi RPM repository"
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf module enable glpi:$glpiversion
sudo dnf -y install yum-utils
sudo dnf install langpacks-en glibc-all-langpacks -y
localectl set-locale LANG=en_US.UTF-8

echo "Step 5: Install GLPI on CentOS 8 / RHEL 8 Linux. Now install the dependencies required and GLPI."
sudo dnf module reset -y php
sudo dnf module install -y php:remi-$phpversion
sudo dnf --enablerepo=remi install php-pear-CAS -y
sudo dnf --enablerepo=remi module install -y glpi:$glpiversion

echo "Step 6: Start and enable httpd service."
sudo systemctl enable httpd
sudo systemctl restart httpd

echo "Step 7: If you have firewalld service, allow http port."
sudo systemctl enable firewalld 
sudo systemctl start firewalld 
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload

echo "Step 8: Turn on some SELinux booleans required."
sudo setsebool -P httpd_can_network_connect on
sudo setsebool -P httpd_can_network_connect_db on
sudo setsebool -P httpd_can_sendmail on

echo "Step 9: Configure GLPI on CentOS 8 / RHEL 8"
#Initial installation from the web browser is only allowed via local access (from the GLPI server). Add your IP address to allow remote installation.
#Add your IP on line 29, it should look like this:"

sudo cat > /etc/httpd/conf.d/glpi.conf <<EOF
<VirtualHost *:80>
DocumentRoot "/usr/share/glpi/"
ServerName glpi
</VirtualHost>

<Directory /usr/share/glpi/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
EOF
sudo systemctl restart httpd

echo "Congratulations. Installation Finish.------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "Acesse http://$glpiacesso and finish configuration" 
echo "SQL server(MariaDB) : $srv"
echo "Usuário SQL : $userdb"
echo "Senha SQL : $pswd"
echo "Select Database : $db"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
