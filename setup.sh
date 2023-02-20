#!/bin/bash

clear

# Confirm setup
read -p "This script will install and configure various software on your server. Do you want to continue? (y/n) " answer
[[ $answer != "y" ]] && echo "Setup cancelled." && exit 0

# Install packages
echo "Installing packages..."
apt-get update && apt-get install -y curl s3cmd glances htop

# Change hostname
read -p "Enter new hostname: " new_hostname
hostnamectl set-hostname "$new_hostname"

# Change timezone
timedatectl set-timezone Asia/Bangkok

# Download and make scripts executable
declare -a scripts=("database.sh" "backup.sh" "monitor.sh")
for script in "${scripts[@]}"; do
  echo "Downloading and making $script executable..."
  curl -o "$script" "https://raw.githubusercontent.com/ManonWorkingArea/server/main/$script"
  chmod +x "$script"
done

# Add aliases for scripts
declare -a aliases=("backup" "database" "monitor")
for alias in "${aliases[@]}"; do
  echo "Adding alias for $alias..."
  echo "alias $alias='/root/$alias.sh'" >> ~/.bashrc
  source ~/.bashrc
done

# Add cron jobs to run scripts
if ! crontab -l | grep -q '/root/backup.sh'; then
  (crontab -l 2>/dev/null; echo "0 * * * * /root/backup.sh") | crontab -
  echo "Added cron job to run backup.sh every hour"
fi

if ! crontab -l | grep -q '/root/monitor.sh'; then
  (crontab -l 2>/dev/null; echo "*/30 * * * * /root/monitor.sh") | crontab -
  echo "Added cron job to run monitor.sh every 30 minutes"
fi

# Set nano as the default editor for crontab -e
echo 'export VISUAL=nano; export EDITOR=nano' >> ~/.bashrc
echo "Nano is now the default editor for crontab -e"

# Set up trigger to reload crontab
echo 'alias crontab="(crontab $@ && service cron reload)"' >> ~/.bashrc
echo "Trigger to reload crontab set up"

# Reload crontab
crontab -l | crontab -
echo "Crontab reloaded"

# Show instructions and server information
echo -e "\nBACKUP INSTRUCTIONS"
echo "To use backup.sh, run './backup.sh' in the terminal. This will create a backup of all databases on the server and upload them to an S3 bucket."
echo "You will need to provide your S3 access key, secret key, endpoint, bucket, and API URL in the backup.sh script before running it."
echo -e "\nDATABASE INSTRUCTIONS"
echo "To use database.sh, run one of the following commands in the terminal:"
echo "./database.sh add to add a new database."
echo "./database.sh delete to delete a database."
echo "./database.sh list to list all databases on the server."
echo "You will need to provide the MySQL root username and password in the database.sh script before running it."
echo -e "\nGLANCES INSTRUCTIONS"
echo "To use glances, run 'glances' in the terminal. This will show server stats."
# Show server information
echo -e "\n\e[1mSERVER INFORMATION\e[0m"
echo "Server IP: $(hostname -I | cut -d ' ' -f1)"
echo "Server state:"
echo "$(uptime)" | sed 's/.*users.*load average: //'
echo "$(free -h | grep Mem | awk '{print "Memory: " $3 " / " $2 " (" $3/$2*100.0 "%)"}')"
echo "$(top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}')"
echo -e "\nSetup complete. Please review the instructions above for how to use the backup.sh and database.sh scripts.\n"