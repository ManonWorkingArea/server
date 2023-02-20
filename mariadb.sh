#!/bin/bash

# Display menu to choose installation, tuning, or restoration
echo -e "\e[1mSelect an option:\e[0m"
echo "1. Install MariaDB"
echo "2. Optimize MariaDB for a high-traffic website"
echo "3. Restore the original configuration"
read -p "Enter the number of the option you want to select: " -r
echo

case $REPLY in
    1)
        # Step 1: Update and upgrade system packages
        echo -e "\e[1mStep 1: Updating system packages\e[0m\n"
        sudo apt update
        sudo apt upgrade -y
        echo -e "---------------------------------------\n"

        # Step 2: Install MariaDB server and client packages
        echo -e "\e[1mStep 2: Installing MariaDB\e[0m\n"
        sudo apt install -y mariadb-server mariadb-client
        echo -e "---------------------------------------\n"

        # Step 3: Secure the MariaDB installation
        echo -e "\e[1mStep 3: Securing the MariaDB installation\e[0m\n"
        sudo mysql_secure_installation
        echo -e "---------------------------------------\n"

        # Step 4: Start and enable the MariaDB service
        echo -e "\e[1mStep 4: Starting and enabling the MariaDB service\e[0m\n"
        sudo systemctl start mariadb
        sudo systemctl enable mariadb
        echo -e "---------------------------------------\n"

        # Step 5: Check MariaDB status
        echo -e "\e[1mStep 5: Checking MariaDB status\e[0m\n"
        sudo systemctl status mariadb
        echo -e "---------------------------------------\n"

        # Step 6: Optional: Install PHP and PHP modules for use with MariaDB
        read -p "Do you want to install PHP and PHP modules for use with MariaDB? (y/n) " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "\e[1mStep 6: Installing PHP and PHP modules\e[0m\n"
            sudo apt install -y php libapache2-mod-php php-mysql
            echo -e "---------------------------------------\n"
        fi

        # Step 7: Optional: Install phpMyAdmin for web-based database management
        read -p "Do you want to install phpMyAdmin for web-based database management? (y/n) " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "\e[1mStep 7: Installing phpMyAdmin\e[0m\n"
            sudo apt install -y phpmyadmin
            echo -e "---------------------------------------\n"
        fi

        # Step 8: Enable remote access
        echo -e "\e[1mStep 8: Enabling remote access for all users\e[0m\n"
        sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak
        sudo sed -i "s/\[mysqld\]/\[mysqld\]\nbind-address = 0.0.0.0\n/" /etc/mysql/mariadb.conf.d/50-server.cnf
		sudo systemctl restart mariadb
		echo -e "---------------------------------------\n"

		echo -e "\"\e[1mInstallation complete!\e[0m"
		;;

    2)
        # Step 9: Optional tuning
        read -p "Do you want to optimize MariaDB for a high-traffic website? This will modify your MariaDB configuration. (y/n) " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup the original mysqld.cnf file
            sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak.tuning

            # Update the mysqld.cnf file with tuning settings
            sudo sed -i "s/^innodb_buffer_pool_size.*/innodb_buffer_pool_size = 70% of available memory/" /etc/mysql/mariadb.conf.d/50-server.cnf
            sudo sed -i "s/^max_connections.*/max_connections = 500/" /etc/mysql/mariadb.conf.d/50-server.cnf
            sudo sed -i "s/^query_cache_size.*/query_cache_size = 256M/" /etc/mysql/mariadb.conf.d/50-server.cnf
            sudo sed -i "s/^query_cache_limit.*/query_cache_limit = 2M/" /etc/mysql/mariadb.conf.d/50-server.cnf
            sudo sed -i "/^\[mysqld\]/a slow_query_log = 1\nlong_query_time = 2\nslow_query_log_file = /var/log/mysql/slow-queries.log" /etc/mysql/mariadb.conf.d/50-server.cnf

            # Restart the MariaDB service
            sudo systemctl restart mariadb

            echo -e "\nMariaDB has been tuned for a high-traffic website."
            echo -e "The original configuration file has been backed up to /etc/mysql/mariadb.conf.d/50-server.cnf.bak.tuning."
            echo -e "To restore the original configuration, run the following command:\n"
            echo -e "sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf.bak.tuning /etc/mysql/mariadb.conf.d/50-server.cnf\n"
        else
            echo "Tuning aborted."
        fi
        ;;

    3)
        # Restore the original configuration
        read -p "This will restore the original MariaDB configuration. Are you sure you want to proceed? (y/n) " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf.bak /etc/mysql/mariadb.conf.d/50-server.cnf
            sudo systemctl restart mariadb

            echo "MariaDB configuration has been restored to the original settings."
        else
            echo "Restoration aborted."
        fi
        ;;

    *)
        echo "Invalid option selected. Aborting script."
        exit 1
esac