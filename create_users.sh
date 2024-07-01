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

# Function to log messages
log_message() {
    echo "$(date): $1" | sudo tee -a $LOG_FILE
}

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Trim leading/trailing whitespace from username and groups
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)
    
    # Check if the user already exists
    if id -u $username >/dev/null 2>&1; then
        log_message "User $username already exists"
        continue
    fi

    # Create the user with a home directory
    sudo useradd -m -s /bin/bash $username
    log_message "Created user $username"

    # Create a group with the same name as the username
    sudo groupadd $username
    sudo usermod -a -G $username $username
    log_message "Created group $username and added $username to it"

    # Add the user to additional groups
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)
        if [ -n "$group" ]; then
            sudo groupadd $group 2>/dev/null
            sudo usermod -a -G $group $username
            log_message "Added $username to group $group"
        fi
    done

    # Generate a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | sudo chpasswd
    log_message "Set password for $username"

    # Store the username and password securely
    echo "$username,$password" | sudo tee -a $PASSWORD_FILE
done < "$FILENAME"

# Final log message
log_message "User creation process completed"
