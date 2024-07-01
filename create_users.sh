#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date): $1" | sudo tee -a $LOG_FILE
}

# Function to trim leading/trailing whitespace
trim() {
    echo "$1" | xargs
}

# Function to create a group if it doesn't exist
create_group_if_not_exists() {
    local group="$1"
    if ! getent group "$group" >/dev/null 2>&1; then
        sudo groupadd "$group"
        log_message "Created group $group"
    fi
}

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

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Debugging output
    echo "Processing user: $username with groups: $groups"

    # Trim leading/trailing whitespace from username and groups
    username=$(trim "$username")
    groups=$(trim "$groups")
    
    # Check if the user already exists
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User $username already exists"
        continue
    fi

    # Create the user with a home directory
    sudo useradd -m -s /bin/bash "$username"
    log_message "Created user $username"

    # Set the primary group to the username's group (if not the same as username)
    if [ "$username" != "$groups" ]; then
        sudo usermod -g "$groups" "$username"
        log_message "Set primary group for $username to $groups"
    fi

    # Add the user to additional groups
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(trim "$group")
        if [ -n "$group" ]; then
            create_group_if_not_exists "$group"
            sudo usermod -a -G "$group" "$username"
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
