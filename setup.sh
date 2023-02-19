#!/bin/bash

# Install packages
apt-get update
apt-get install -y mariadb-server curl s3cmd glances htop

# Change hostname
read -p "Enter new hostname: " new_hostname
hostnamectl set-hostname $new_hostname

# Change timezone
timedatectl set-timezone Asia/Bangkok

# Configure Mariadb for remote access
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# Add firewall rule for Mariadb SQL port
ufw allow 3306/tcp

# Enable firewall
ufw --force enable

# Download and make executable database.sh
curl -o database.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/database.sh
chmod +x database.sh

# Download and make executable backup.sh
curl -o backup.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/backup.sh
chmod +x backup.sh

# Add alias for backup
echo "alias backup='/root/backup.sh'" >> ~/.bashrc
source ~/.bashrc

echo "alias database='/root/database.sh'" >> ~/.bashrc
source ~/.bashrc