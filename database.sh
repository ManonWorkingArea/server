#!/bin/bash

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
  *)
    echo "Usage: $0 {add|delete|list}"
    exit 1
    ;;
esac