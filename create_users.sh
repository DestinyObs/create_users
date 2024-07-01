#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date): $1" | sudo tee -a "$LOG_FILE"
}

# Function to trim leading/trailing whitespace
trim() {
    echo "$1" | xargs
}

# Function to create a group if it doesn't exist
create_group_if_not_exists() {
    local group="$1"
    IFS=',' read -r -a group_parts <<< "$group"
    for part in "${group_parts[@]}"; do
        if ! getent group "$part" >/dev/null 2>&1; then
            sudo groupadd "$part"
            if [ $? -eq 0 ]; then
                log_message "Created group $part"
            else
                log_message "Failed to create group $part"
            fi
        fi
    done
}

# Check if the script received the filename as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILENAME="$1"

# Log file and secure password file locations
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the log and password directories exist
sudo mkdir -p /var/log
sudo mkdir -p /var/secure

# Create or clear log and password files
sudo truncate -s 0 "$LOG_FILE"
sudo truncate -s 0 "$PASSWORD_FILE"

# Set secure permissions for the password file
sudo chmod 600 "$PASSWORD_FILE"

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Debugging output
    echo "Processing user: $username with groups: $groups"

    # Trim leading/trailing whitespace from username and groups
    username=$(trim "$username")
    groups=$(trim "$groups")
    
    # Validate username and group names
    if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
        log_message "Invalid username: $username"
        continue
    fi

    # Check if the user already exists
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User $username already exists"
        continue
    fi

    # Create the user with a home directory and set permissions
    sudo useradd -m -s /bin/bash "$username"
    if [ $? -eq 0 ]; then
        log_message "Created user $username"
        # Set permissions for home directory
        sudo chmod 700 "/home/$username"
    else
        log_message "Failed to create user $username"
        continue
    fi

    # Set the primary group to the username's group (if not the same as username)
    if [ "$username" != "$groups" ]; then
        sudo usermod -g "$groups" "$username"
        if [ $? -eq 0 ]; then
            log_message "Set primary group for $username to $groups"
        else
            log_message "Failed to set primary group for $username to $groups"
        fi
    fi

    # Add the user to additional groups
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(trim "$group")
        if [ -n "$group" ]; then
            create_group_if_not_exists "$group"
            if getent group "$group" | grep &>/dev/null "\b$username\b"; then
                log_message "$username is already a member of group $group"
            else
                sudo usermod -a -G "$group" "$username"
                if [ $? -eq 0 ]; then
                    log_message "Added $username to group $group"
                else
                    log_message "Failed to add $username to group $group"
                fi
            fi
        fi
    done

    # Generate a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        log_message "Set password for $username"
    else
        log_message "Failed to set password for $username"
    fi

    # Store the username and password securely
    echo "$username,$password" | sudo tee -a "$PASSWORD_FILE"
done < "$FILENAME"

# Final log message
log_message "User creation process completed"
