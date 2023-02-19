#!/bin/bash

echo -e "\e[1mThis script will install and configure various software on your server.\e[0m"
read -p "Do you want to continue? (y/n) " answer

if [[ $answer != "y" ]]; then
  echo "Setup cancelled."
  exit 0
fi

# Install packages
clear
echo "Installing packages..."
apt-get update
apt-get install -y mariadb-server curl s3cmd glances htop
echo "Done installing packages."

# Change hostname
clear
echo "Changing hostname..."
read -p "Enter new hostname: " new_hostname
hostnamectl set-hostname $new_hostname
echo "Done changing hostname."

# Change timezone
clear
echo "Changing timezone..."
timedatectl set-timezone Asia/Bangkok
echo "Done changing timezone."

# Configure Mariadb for remote access
clear
echo "Configuring MariaDB for remote access..."
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"
echo "Done configuring MariaDB."

# Add firewall rule for Mariadb SQL port
clear
echo "Adding firewall rule for MariaDB SQL port..."
ufw allow 3306/tcp
echo "Done adding firewall rule."

# Enable firewall
clear
echo "Enabling firewall..."
ufw --force enable
echo "Done enabling firewall."

# Download and make executable database.sh
clear
echo "Downloading and making database.sh executable..."
curl -o database.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/database.sh
chmod +x database.sh
echo "Done downloading and making database.sh executable."

# Download and make executable backup.sh
clear
echo "Downloading and making backup.sh executable..."
curl -o backup.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/backup.sh
chmod +x backup.sh
echo "Done downloading and making backup.sh executable."

# Add alias for backup
clear
echo "Adding alias for backup..."
echo "alias backup='/root/backup.sh'" >> ~/.bashrc
source ~/.bashrc
echo "Done adding alias for backup."

# Add alias for database
clear
echo "Adding alias for database..."
echo "alias database='/root/database.sh'" >> ~/.bashrc
source ~/.bashrc
echo "Done adding alias for database."

# Get the server's IP address and display it to the user
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\e[1mServer IP address:\e[0m $SERVER_IP"

# Show instructions
echo -e "\e[1mTo use backup.sh\e[0m, run \e[1m'backup'\e[0m in the terminal. This will create a backup of all databases on the server and upload them to an S3 bucket. You will need to provide your S3 access key, secret key, endpoint, bucket, and API URL in the backup.sh script before running it."

echo -e "\e[1mTo use database.sh\e[0m, run \e[1m'database'\e[0m in the terminal. This will allow you to add, delete, or list databases on the server. You will need to provide the MySQL root username and password in the database.sh script before running it."

