#!/bin/bash

# Check if alias name for database exists, and if not, add a new alias
if ! grep -q "alias $1='bash /root/database.sh'" ~/.bashrc ; then
  echo "alias $1='bash /root/database.sh'" >> ~/.bashrc
fi

case "$1" in
  add)
    read -p "Enter database name: " dbname
    read -p "Enter database admin username: " dbuser
    read -s -p "Enter database admin password: " dbpass

    mysql -u root -e "CREATE DATABASE \`$dbname\`;"
    mysql -u root -e "GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    read -p "Would you like to add a user to the database? (y/n): " adduser
    if [[ \$adduser == "y" ]]; then
      read -p "Enter username: " username
      read -s -p "Enter password: " userpass
      mysql -u root -e "GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$username'@'localhost' IDENTIFIED BY '$userpass';"
      mysql -u root -e "FLUSH PRIVILEGES;"
      echo "User \`$username\` added to database \`$dbname\` with password \`$userpass\`."
    fi
    ;;
  delete)
    read -p "Enter database name to delete: " dbname
    mysql -u root -e "DROP DATABASE \`$dbname\`;"
    echo "Database \`$dbname\` deleted."
    ;;
  list)
    mysql -u root -e "SHOW DATABASES;"
    ;;
   remote)
    read -p "Enter username: " username
    # Check if user already exists
    user_exists=$(mysql -u root -sN -e "SELECT COUNT(*) FROM mysql.user WHERE user = '$username'")
    if [ "$user_exists" -eq 1 ]; then
      # User already exists, grant remote access to all databases
      mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'%'"
      mysql -u root -e "FLUSH PRIVILEGES;"
      echo "Remote access granted to user \`$username\` for all databases."
    else
      # User does not exist, prompt to create a new user
      read -p "User \`$username\` does not exist. Would you like to add the user? (y/n): " adduser
      if [[ \$adduser == "y" ]]; then
        read -p "Enter database admin username: " dbuser
        read -s -p "Enter database admin password: " dbpass
        mysql -u root -e "CREATE USER '$username'@'%' IDENTIFIED BY '$dbpass';"
        mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'%' IDENTIFIED BY '$dbpass';"
        mysql -u root -e "FLUSH PRIVILEGES;"
        echo "User \`$username\` added to MySQL with password \`$dbpass\` and granted remote access to all databases."
      else
        echo "User \`$username\` does not exist and was not added. Remote access was not granted."
      fi
    fi
    ;;
    password)
    read -p "Enter username: " username

    # Check if user exists
    user_exists=$(mysql -u root -sN -e "SELECT COUNT(*) FROM mysql.user WHERE user = '$username'")
    if [ "$user_exists" -eq 1 ]; then
      read -s -p "Enter new password for user \`$username\`: " userpass
      mysql -u root -e "ALTER USER '$username'@'localhost' IDENTIFIED BY '$userpass';"
      mysql -u root -e "FLUSH PRIVILEGES;"
      echo "Password for user \`$username\` changed."
    else
      echo "User \`$username\` does not exist."
    fi
    ;;
  *)
    echo "Usage: $0 {add|delete|list|remote|password}"
    exit 1
    ;;

esac
