#!/bin/bash

# Get the path to the directory containing this script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the configuration file
config_file="$script_dir/cpu_monitor.conf"

# Load the configuration file if it exists
if [ -f "$config_file" ]; then
  source "$config_file"
fi

# Prompt the user to add the API URL if it's not set
if [ -z "$API_URL" ]; then
  read -p "Please enter the API URL: " API_URL
  echo "API_URL=$API_URL" >> "$config_file"
fi

# Prompt the user to add the CPU load threshold if it's not set
if [ -z "$LOAD_THRESHOLD" ]; then
  read -p "Please enter the CPU load threshold (in percent): " LOAD_THRESHOLD
  echo "LOAD_THRESHOLD=$LOAD_THRESHOLD" >> "$config_file"
fi

# Check if the crontab job already exists
if ! crontab -l | grep -q "cpu_monitor.sh"; then
  # Add the crontab job to run every 5 minutes
  (crontab -l ; echo "*/5 * * * * $script_dir/cpu_monitor.sh") | crontab -
fi

# Loop forever
while true
do
  # Get the current CPU usage as a percentage
  cpu_load=$(top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}')

  # Check if the CPU usage is over the threshold
  if (( $(echo "$cpu_load > $LOAD_THRESHOLD" | bc -l) ))
  then
    # Call the API URL using cURL
    curl -X GET $API_URL
  fi

  # Sleep for 10 seconds before checking the CPU usage again
  sleep 10
done
