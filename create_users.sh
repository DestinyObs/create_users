#!/bin/bash

# Check if the script received the filename as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILENAME=$1

# Log file and secure password file locations
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the log and password directories exist
sudo mkdir -p /var/log
sudo mkdir -p /var/secure

# Create or clear log and password files
sudo truncate -s 0 $LOG_FILE
sudo truncate -s 0 $PASSWORD_FILE

# Set secure permissions for the password file
sudo chmod 600 $PASSWORD_FILE
