#!/bin/bash

# Check if API URL is set
if [ -z "$API_URL" ]; then
  read -p "Enter the API URL to send server information: " API_URL
  echo "API_URL=$API_URL" >> /root/monitor.sh
fi

# Get server stats
UPTIME=$(uptime)
CPU_LOAD=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
CPU_CORES=$(nproc)
MEMORY_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEMORY_USED=$(free -h | grep Mem | awk '{print $3}')
MEMORY_FREE=$(free -h | grep Mem | awk '{print $4}')
DISK_TOTAL=$(df -h / | tail -n 1 | awk '{print $2}')
DISK_USED=$(df -h / | tail -n 1 | awk '{print $3}')
DISK_FREE=$(df -h / | tail -n 1 | awk '{print $4}')
SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')
SWAP_USED=$(free -h | grep Swap | awk '{print $3}')
SWAP_FREE=$(free -h | grep Swap | awk '{print $4}')

# Get server hostname and IP address
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Send server stats to API endpoint
curl -s -X POST -d "hostname=$HOSTNAME&ip_address=$IP_ADDRESS&uptime=$UPTIME&cpu_load=$CPU_LOAD&cpu_cores=$CPU_CORES&memory_total=$MEMORY_TOTAL&memory_used=$MEMORY_USED&memory_free=$MEMORY_FREE&disk_total=$DISK_TOTAL&disk_used=$DISK_USED&disk_free=$DISK_FREE&swap_total=$SWAP_TOTAL&swap_used=$SWAP_USED&swap_free=$SWAP_FREE" $API_URL > /dev/null
