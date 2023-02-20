#!/bin/bash

# Display menu to choose installation, tuning, or restoration
echo -e "\e[1mSelect an option:\e[0m"
echo "1. Install Nginx and PHP 5.6"
echo "2. Optimize Nginx and PHP for a high-traffic website"
echo "3. Restore the original configuration"
echo "4. Set up a new website"
read -p "Enter the number of the option you want to select: " -r
echo

case $REPLY in
    1)
        # Step 1: Update and upgrade system packages
        echo -e "\e[1mStep 1: Updating system packages\e[0m\n"
        sudo apt update
        sudo apt upgrade -y
        echo -e "---------------------------------------\n"

        # Step 2: Install Nginx
        echo -e "\e[1mStep 2: Installing Nginx\e[0m\n"
        sudo apt install -y nginx
        echo -e "---------------------------------------\n"

        # Step 3: Install PHP 5.6 and some commonly used PHP modules
        echo -e "\e[1mStep 3: Installing PHP 5.6 and some commonly used PHP modules\e[0m\n"
        sudo apt install -y php5.6-fpm php5.6-cli php5.6-mysql php5.6-curl php5.6-gd php5.6-mcrypt php5.6-intl php5.6-xsl php5.6-mbstring php5.6-xml
        echo -e "---------------------------------------\n"

        # Step 4: Configure PHP-FPM
        echo -e "\e[1mStep 4: Configuring PHP-FPM\e[0m\n"
        sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/5.6/fpm/php.ini
        sudo systemctl restart php5.6-fpm
        echo -e "---------------------------------------\n"

        # Step 5: Configure Nginx to use PHP-FPM
        echo -e "\e[1mStep 5: Configuring Nginx to use PHP-FPM\e[0m\n"
        sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
        sudo sed -i "s/index index.html index.htm index.nginx-debian.html;/index index.php index.html index.htm index.nginx-debian.html;/" /etc/nginx/sites-available/default
        sudo sed -i "s/#location ~ \\\.php$ {/location ~ \\\.php$ {\n    include snippets/fastcgi-php.conf;\n    fastcgi_pass unix:\/run\/php\/php5.6-fpm.sock;\n}/" /etc/nginx/sites-available/default
        sudo systemctl restart nginx
        echo -e "---------------------------------------\n"

        echo -e "\e[1mNginx and PHP 5.6 installation complete!\e[0m"
        ;;

    2)
        # Step 6: Optional tuning
        read -p "Do you want to optimize Nginx and PHP for a high-traffic website? This will modify your Nginx and PHP configuration. (y/n) " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup the original configuration files
            sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.tuning
                        sudo cp /etc/php/5.6/fpm/php.ini /etc/php/5.6/fpm/php.ini.bak.tuning
            sudo cp /etc/php/5.6/fpm/pool.d/www.conf /etc/php/5.6/fpm/pool.d/www.conf.bak.tuning

            # Update the Nginx configuration with tuning settings
            sudo sed -i "s/worker_processes auto;/worker_processes auto;\nworker_rlimit_nofile 100000;/" /etc/nginx/nginx.conf
            sudo sed -i "s/# server_tokens off;/server_tokens off;/" /etc/nginx/nginx.conf

            # Update the PHP-FPM configuration with tuning settings
            sudo sed -i "s/^pm.max_children.*/pm.max_children = 50/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^pm.start_servers.*/pm.start_servers = 5/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^pm.min_spare_servers.*/pm.min_spare_servers = 5/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^pm.max_spare_servers.*/pm.max_spare_servers = 10/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^;pm.max_requests.*/pm.max_requests = 500/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^listen = .*/listen = \/run\/php\/php5.6-fpm.sock/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^;listen.owner.*/listen.owner = www-data/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^;listen.group.*/listen.group = www-data/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^;listen.mode.*/listen.mode = 0660/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^;request_terminate_timeout.*/request_terminate_timeout = 60/" /etc/php/5.6/fpm/pool.d/www.conf
            sudo sed -i "s/^;slowlog.*/slowlog = \/var\/log\/php5.6-fpm.log.slow/" /etc/php/5.6/fpm/pool.d/www.conf

            # Restart Nginx and PHP-FPM
            sudo systemctl restart nginx
            sudo systemctl restart php5.6-fpm

            echo -e "\nNginx and PHP have been optimized for a high-traffic website."
            echo -e "The original configuration files have been backed up to /etc/nginx/nginx.conf.bak.tuning, /etc/php/5.6/fpm/php.ini.bak.tuning, and /etc/php/5.6/fpm/pool.d/www.conf.bak.tuning."
            echo -e "To restore the original configurations, run the following commands:\n"
            echo -e "sudo cp /etc/nginx/nginx.conf.bak.tuning /etc/nginx/nginx.conf"
            echo -e "sudo cp /etc/php/5.6/fpm/php.ini.bak.tuning /etc/php/5.6/fpm/php.ini"
            echo -e "sudo cp /etc/php/5.6/fpm/pool.d/www.conf.bak.tuning /etc/php/5.6/fpm/pool.d/www.conf"
            echo -e "sudo systemctl restart nginx"
            echo -e "sudo systemctl restart php5.6-fpm\n"
        else
            echo "Tuning aborted."
        fi
        ;;

    3)
        # Restore the original configuration
        read -p "This will restore the original Nginx and PHP configuration. Are you sure you want to proceed? (y/n) " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo cp /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
            sudo cp /etc/php/5.6/fpm/php.ini.bak /etc/php/5.6/fpm/php.ini
            sudo cp /etc/php/5.6/fpm/pool.d/www.conf.bak /etc/php/5.6/fpm/pool.d/www.conf
            sudo systemctl restart nginx
            sudo systemctl restart php5.6-fpm

            echo "Nginx and PHP configuration has been restored to the original settings."
        else
            echo "Restoration aborted."
        fi
        ;;
            4)
        # Step 1: Add DNS entry for the new website
        echo -e "\e[1mStep 1: Adding DNS entry for the new website\e[0m\n"
        read -p "Enter the domain name for the new website: " domain_name
        read -p "Enter the IP address of the server: " ip_address
        echo "$ip_address $domain_name" | sudo tee -a /etc/hosts
        echo -e "DNS entry added for $domain_name.\n"
        echo -e "---------------------------------------\n"

        # Step 2: Create the website directory
        echo -e "\e[1mStep 2: Creating the website directory\e[0m\n"
        read -p "Enter the username for the new website owner: " username
        sudo mkdir -p /var/www/$domain_name/html
        sudo chown -R $username:$username /var/www/$domain_name/html
        sudo chmod -R 755 /var/www/$domain_name
        echo "Website directory created at /var/www/$domain_name/html."
        echo -e "---------------------------------------\n"

        # Step 3: Create an Nginx server block for the new website
        echo -e "\e[1mStep 3: Creating an Nginx server block for the new website\e[0m\n"
        sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/server_name _;/server_name $domain_name;/g" /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/root \/var\/www\/html;/root \/var\/www\/$domain_name\/html;/g" /etc/nginx/sites-available/$domain_name
        sudo ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/
        sudo nginx -t
        sudo systemctl reload nginx
        echo "Nginx server block created for $domain_name."
        echo -e "---------------------------------------\n"

        # Step 4: Install Let's Encrypt SSL certificate
        echo -e "\e[1mStep 4: Installing Let's Encrypt SSL certificate\e[0m\n"
        sudo apt install -y certbot python3-certbot-nginx
        sudo certbot --nginx --non-interactive --agree-tos -m admin@$domain_name -d $domain_name
        echo "Let's Encrypt SSL certificate installed for $domain_name."
        echo -e "---------------------------------------\n"

        # Step 5: Add FTP user
        echo -e "\e[1mStep 5: Adding FTP user for $username\e[0m\n"
        read -p "Enter the desired FTP username for the website: " ftp_user
        sudo adduser $ftp_user
        sudo usermod -aG www-data $ftp_user
        sudo chown -R $ftp_user:www-data /var/www/$domain_name
        sudo chmod -R 775 /var/www/$domain_name
        echo "FTP user $ftp_user added for $username."
        echo -e "---------------------------------------\n"

        echo -e "\e[1mNew website setup complete!\e[0m"
        ;;
esac


