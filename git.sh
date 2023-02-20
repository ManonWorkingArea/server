#!/bin/bash

echo "Select an option:"
echo "1. Set up a new website"
echo "2. Quit"
read option

case $option in
    1)
        # Step 1: Adding DNS entry for the new website
        read -p "Enter the domain name for the website: " domain_name
        sudo sed -i "s/localhost/$domain_name/g" /etc/nginx/sites-available/default

        # Step 2: Setting up virtual host in Nginx
        sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/server_name _/server_name $domain_name/g" /etc/nginx/sites-available/$domain_name
        sudo ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/
        sudo systemctl reload nginx

        # Step 3: Clone the Git repository
        read -p "Enter the Git repository URL for the website: " git_url
        sudo apt install -y git
        sudo git clone $git_url /var/www/$domain_name/html/.

        # Step 4: Set up automatic updates with Git hooks
        read -p "Enter the email address for the Git hook: " email_address
        sudo mkdir -p /var/www/$domain_name/html/.git/hooks
        sudo bash -c "cat > /var/www/$domain_name/html/.git/hooks/post-receive" << EOF
#!/bin/bash
git --work-tree=/var/www/$domain_name/html --git-dir=/var/www/$domain_name/html/.git checkout -f
EOF
        sudo chmod +x /var/www/$domain_name/html/.git/hooks/post-receive
        sudo git config --global user.email "$email_address"

        # Step 5: Configure Cloudflare SSL
        read -p "Enter the Cloudflare email address: " cf_email
        read -p "Enter the Cloudflare API key: " cf_api_key
        sudo apt install -y ruby-full
        sudo gem install cloudflare
        sudo cloudflare cert create --email $cf_email --key $cf_api_key --domains $domain_name
        sudo sed -i "s/# ssl_certificate/ssl_certificate/g" /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/# ssl_certificate_key/ssl_certificate_key/g" /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/letsencrypt\/live\/$domain_name\/fullchain.pem;/g" /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/letsencrypt\/live\/$domain_name\/privkey.pem;/g" /etc/nginx/sites-available/$domain_name
        sudo sed -i "s/# listen 443 ssl http2/listen 443 ssl http2/g" /etc/nginx/sites-available/$domain_name
        sudo systemctl reload nginx

        echo "Website set up complete!"
        echo "You can now visit the website at http://$domain_name"
        ;;
    2)
        echo "Exiting script."
        exit
        ;;
    *)
        echo "Invalid option. Exiting script."
        exit 1
        ;;
esac
