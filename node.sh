#!/bin/bash

# Display menu
echo -e "\e[1mSelect an option:\e[0m"
echo "1. Install Node.js"
echo "2. Add domain and Git repository"
echo "3. Remove domain and Git repository"
echo "4. Tune server for high-load websites"
read -p "Enter the number of the option you want to select: " -r
echo

case $REPLY in
    1)
        # Install Node.js
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo apt-get install -y build-essential
        ;;
    2)
        # Add domain and Git repository
        read -p "Enter domain name: " domain_name

        # Set up Nginx server block for domain
        sudo tee /etc/nginx/sites-available/$domain_name >/dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $domain_name;

    location / {
        root /var/www/$domain_name/dist;
        try_files \$uri /index.html;
    }
}
EOF

        # Create directory and clone Git repository
        sudo mkdir -p /var/www/$domain_name
        read -p "Enter Git repository URL: " git_url
        git clone $git_url /var/www/$domain_name

        # Set up post-receive hook to update source and build automatically
        sudo tee /var/www/$domain_name/.git/hooks/post-receive >/dev/null <<EOF
#!/bin/bash

cd /var/www/$domain_name

git fetch
git reset --hard origin/master

npm install
npm run build

sudo cp -r /var/www/$domain_name/dist/* /var/www/$domain_name/
sudo systemctl reload nginx
EOF

        sudo chmod +x /var/www/$domain_name/.git/hooks/post-receive
        sudo chown -R $USER:$USER /var/www/$domain_name
        sudo ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/
        sudo systemctl reload nginx
        ;;
    3)
        # Remove domain and Git repository
        read -p "Enter domain name: " domain_name

        # Remove the server block
        sudo rm /etc/nginx/sites-available/$domain_name
        sudo rm /etc/nginx/sites-enabled/$domain_name

        # Reload Nginx to apply changes
        sudo systemctl reload nginx

        # Remove the project directory
        sudo rm -rf /var/www/$domain_name
        ;;
    4)
        # Tune server for high-load websites
        echo "Tuning server for high-load websites..."
        # Add tuning commands here
        sudo apt-get update
        sudo apt-get install -y nginx nodejs npm build-essential

        # Set kernel settings for web applications
        echo "net.core.somaxconn = 1024" | sudo tee -a /etc/sysctl.conf
        echo "net.core.netdev_max_backlog = 5000" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_max_syn_backlog = 20480" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_tw_reuse = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_fin_timeout = 30" | sudo tee -a /etc/sysctl.conf

        # Apply changes
        sudo sysctl -p

        # Configure Nginx as a reverse proxy cache
        sudo tee /etc/nginx/nginx.conf >/dev/null <<EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    # Accept as many connections as possible, but don't allow more than 65535 connections at once
    multi_accept on;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Cache settings
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m inactive=60m;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    proxy_cache_valid 200 60m;
    proxy_cache_valid 404 1m;

    # Load balancing
    upstream backend {
        server 127.0.0.1:8000;
        server 127.0.0.1:8001;
    }

    # Server block for the website
    server {
        listen 80;
        listen [::]:80;
        server_name $domain_name;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
            proxy_redirect off;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_http_version 1.1;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

        sudo systemctl restart nginx
        ;;
    *)
        echo "Invalid option"
        ;;
esac

