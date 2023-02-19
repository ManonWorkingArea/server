#!/bin/bash

# Install packages
apt-get update
apt-get install -y mariadb-server curl s3cmd glances htop

# Change hostname
read -p "Enter new hostname: " new_hostname
hostnamectl set-hostname $new_hostname

# Change timezone
timedatectl set-timezone Asia/Bangkok

# Update and upgrade
apt-get update
apt-get upgrade -y

# Optimize system for best performance
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "fs.file-max=2097152" >> /etc/sysctl.conf
echo "kernel.pid_max=4194304" >> /etc/sysctl.conf
echo "kernel.sysrq=1" >> /etc/sysctl.conf
echo "fs.nr_open=1048576" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=8192" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout=10" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time=300" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range=1024 65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle=1" >> /etc/sysctl.conf
sysctl -p

# Configure Mariadb for remote access
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# Add firewall rule for Mariadb SQL port
ufw allow 3306/tcp

# Enable firewall
ufw --force enable

# Add alias for backup
echo "alias backup='/root/backup.sh'" >> ~/.bashrc
source ~/.bashrc

# Add alias for Glances
echo "alias monitor='glances -w'" >> ~/.bashrc
source ~/.bashrc