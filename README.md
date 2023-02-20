
# Server Configuration Script

This script will install and configure various software on your server.

## Getting Started

To use the script, first SSH into your server as the root user or a user with sudo privileges. Then run the following command to download the script:

bashCopy code

`wget --no-cache https://raw.githubusercontent.com/ManonWorkingArea/server/main/setup.sh` 

Next, make the script executable with the following command:

bashCopy code

`chmod +x setup.sh` 

Finally, run the script with the following command:

bashCopy code

`./setup.sh` 

The script will guide you through the process of installing and configuring software on your server.


## Getting Started

To use the script, first SSH into your server as the root user or a user with sudo privileges. Then run the following command to download the script:

bashCopy code

`wget --no-cache https://raw.githubusercontent.com/ManonWorkingArea/server/main/cpu_monitor.sh` 

Next, make the script executable with the following command:

bashCopy code

`chmod +x cpu_monitor.sh` 

Finally, run the script with the following command:

bashCopy code

`./cpu_monitor.sh` 

The script will guide you through the process of installing and configuring software on your server.

## Additional Options

### Running Backup Script Automatically

If you want to run the backup script automatically every hour, you can add a cron job to your server. To do this, run the following command:

Copy code

`crontab -e` 

This will open your crontab file in a text editor. Add the following line to the bottom of the file:

javascriptCopy code

`0 * * * * /root/backup.sh >/dev/null 2>&1` 

Save the file and exit the editor. This will run the backup script every hour.

### Monitoring Server Stats

The `monitor.sh` script can be used to monitor your server's stats and send them to an API endpoint. To use this script, first create a `monitor.conf` file in the root directory with the following content:

makefileCopy code

`API_URL=` 

Replace the `API_URL` value with the URL of the API endpoint you want to send the server stats to.

Then, download and make the script executable with the following commands:

bashCopy code

`curl -o monitor.sh https://raw.githubusercontent.com/ManonWorkingArea/server/main/monitor.sh
chmod +x monitor.sh` 

To run the script, use the following command:

bashCopy code

`./monitor.sh` 

This will send your server stats to the API endpoint specified in the `monitor.conf` file. You can add a cron job to run the script every half hour by adding the following line to your crontab file:

javascriptCopy code

`*/30 * * * * /root/monitor.sh >/dev/null 2>&1` 

## Contact

If you have any questions or issues with the script, please contact me at [contact@myemail.com](mailto:contact@myemail.com).
