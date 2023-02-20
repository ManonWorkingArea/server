#!/bin/bash

completed_tasks=()

echo -e "#############################################"
echo -e "\e[1mThis script will install and configure various software on your server.\e[0m"
read -p "Do you want to continue? (y/n) " answer

if [[ $answer != "y" ]]; then
  echo "Setup cancelled."
  exit 0
fi

# Install packages
echo -e "\e[1m1.Installing packages...\e[0m"
apt-get update
apt-get install -y mariadb-server curl s3cmd glances htop
echo "Done installing packages."
completed_tasks+=("Install packages")
echo -e "#############################################\n"

# Change hostname
echo -e "\e[1m2.Changing hostname...\e[0m"
read -p "Enter new hostname: " new_hostname
hostnamectl set-hostname $new_hostname
echo "Done changing hostname."
completed_tasks+=("Change hostname")
echo -e "#############################################\n"

# Change timezone
echo -e "\e[1m3.Changing timezone...\e[0m"
timedatectl set-timezone Asia/Bangkok
echo "Done changing timezone."
completed_tasks+=("Change timezone")
echo -e "#############################################\n"

# Configure Mariadb for remote access
echo -e "\e[1m4.Configuring MariaDB for remote access...\e[0m"
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"
echo "Done configuring MariaDB."
completed_tasks+=("Configure MariaDB")
echo -e "#############################################\n"

# Add firewall rule for Mariadb SQL port
echo -e "\e[1m5.Adding firewall rule for MariaDB SQL port...\e[0m"
ufw allow 3306/tcp
echo "Done adding firewall rule."
completed_tasks+=("Add firewall rule for MariaDB")
echo -e "#############################################\n"

# Enable firewall
echo -e "\e[1m6.Enabling firewall...\e[0m"
ufw --force enable
echo "Done enabling firewall."
completed_tasks+=("Enable firewall")
echo -e "#############################################\n"

# Download and make executable database.sh
echo -e "\e[1m7.Downloading and making database.sh executable...\e[0m"
curl -o database.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/database.sh
chmod +x database.sh
echo "Done downloading and making database.sh executable."
completed_tasks+=("Download and make database.sh executable")
echo -e "#############################################\n"

# Download and make executable backup.sh
echo -e "\e[1m8.Downloading and making backup.sh executable...\e[0m"
curl -o backup.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/backup.sh
chmod +x backup.sh
echo "Done downloading and making backup.sh executable."
completed_tasks+=("Download and make backup.sh executable")
echo -e "#############################################\n"

# Download and make executable monitor.sh
echo -e "\e[1m9.Downloading and making backup.sh executable...\e[0m"
curl -o monitor.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/monitor.sh
chmod +x monitor.sh
echo "Done downloading and making monitor.sh executable."
completed_tasks+=("Download and make monils
tor.sh executable")
echo -e "#############################################\n"

# Add alias for backup
echo -e "\e[1m10.Adding alias for backup...\e[0m"
echo "alias backup='/root/backup.sh'" >> ~/.bashrc
source ~/.bashrc
echo "Done adding alias for backup."
completed_tasks+=("Add alias for backup")
echo -e "#############################################\n"

# Add alias for database
echo -e "\e[1m11.Adding alias for database...\e[0m"
echo "alias database='/root/database.sh'" >> ~/.bashrc
source ~/.bashrc
echo "Done adding alias for database."
completed_tasks+=("Add alias for database")
echo -e "#############################################\n"

# Add alias for monitor
echo -e "\e[1m12.Adding alias for monitor...\e[0m"
echo "alias monitor='/root/monitor.sh'" >> ~/.bashrc
source ~/.bashrc
echo "Done adding alias for monitor."
completed_tasks+=("Add alias for monitor")
echo -e "#############################################\n"


# Add cron job to run backup.sh every hour
echo -e "\e[1m13.Add cron job to run backup.sh every hour...\e[0m"
(crontab -l 2>/dev/null; echo "0 * * * * /root/backup.sh") | crontab -
completed_tasks+=("Added cron job to run backup.sh every hour")
echo -e "#############################################\n"

# Add cron job to run monitor.sh every hour
echo -e "\e[1m14.Add cron job to run monitor.sh every hour...\e[0m"
(crontab -l 2>/dev/null; echo "*/30 * * * * /root/monitor.sh") | crontab -
completed_tasks+=("Added cron job to run monitor.sh every hour")
echo -e "#############################################\n"

# Show instructions
echo -e "\n\e[1mBACKUP INSTRUCTIONS\e[0m"
echo -e "\nTo use backup.sh, run \e[1m'./backup.sh'\e[0m in the terminal. This will create a backup of all databases on the server and upload them to an S3 bucket."
echo -e "You will need to provide your S3 access key, secret key, endpoint, bucket, and API URL in the backup.sh script before running it."

echo -e "\n\e[1mDATABASE INSTRUCTIONS\e[0m"
echo -e "\nTo use database.sh, run one of the following commands in the terminal:"
echo -e "\e[1m./database.sh add\e[0m to add a new database."
echo -e "\e[1m./database.sh delete\e[0m to delete a database."
echo -e "\e[1m./database.sh list\e[0m to list all databases on the server."
echo -e "You will need to provide the MySQL root username and password in the database.sh script before running it."

echo -e "\n\e[1mGLANCES INSTRUCTIONS\e[0m"
echo -e "\nTo use glances, run \e[1m'glances'\e[0m in the terminal. This will show server stat"

# Show server information
echo -e "\n\e[1mSERVER INFORMATION\e[0m"
echo "Server IP: $(hostname -I | cut -d ' ' -f1)"
echo "Server state:"
echo "$(uptime)" | sed 's/.*users.*load average: //'
echo "$(free -h | grep Mem | awk '{print "Memory: " $3 " / " $2 " (" $3/$2*100.0 "%)"}')"
echo "$(top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}')"

# Show list of completed tasks
echo -e "\n\e[1mCOMPLETED TASKS\e[0m"
for task in "${completed_tasks[@]}"; do
    echo "- $task"
done

echo -e "\nSetup complete. Please review the instructions above for how to use the backup.sh and database.sh scripts.\n"


