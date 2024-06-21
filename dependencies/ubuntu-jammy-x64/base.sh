#!/bin/bash

set -e

# Get the current directory of the script
getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

# Install a package if not already installed
install_package() {
    local package_name=$1
    if ! check_installed "$package_name"; then
        sudo apt-get update -y
        sudo apt-get install -y "$package_name" || handle_error "Failed to install $package_name"
    fi
}

# Check if a program is installed
check_installed() {
    local program_name=$1
    if ! command -v "$program_name" &> /dev/null; then
        return 1
    fi
    return 0
}

# Prompt user for input securely
prompt_input() {
    local prompt_message=$1
    read -r -p "$prompt_message" user_input
    echo "$user_input"
}

# Handle errors with custom messages
handle_error() {
    local error_message=$1
    echo "Error: $error_message" >&2
    exit 1
}

# Function to enable a service
enable_service() {
    local service_name=$1
    sudo systemctl enable "$service_name" || handle_error "Failed to enable $service_name"
    sudo systemctl start "$service_name" || handle_error "Failed to start $service_name"
}

# Function to add a new user
add_user() {
    local username=$1
    sudo adduser "$username" || handle_error "Failed to add user $username"
}

# Function to add a user to a group
add_user_to_group() {
    local username=$1
    local groupname=$2
    sudo usermod -aG "$groupname" "$username" || handle_error "Failed to add $username to $groupname"
}

# Function to create a backup of a file
backup_file() {
    local file_path=$1
    local backup_path="${file_path}.bak"
    cp "$file_path" "$backup_path" || handle_error "Failed to backup $file_path"
}

# Function to configure a firewall rule
configure_firewall() {
    local rule=$1
    sudo ufw "$rule" || handle_error "Failed to configure firewall rule: $rule"
}

# Function to check if a service is active
is_service_active() {
    local service_name=$1
    sudo systemctl is-active --quiet "$service_name"
}

echo "Base.sh executed successfully!"