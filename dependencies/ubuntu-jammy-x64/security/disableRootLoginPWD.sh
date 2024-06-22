#!/bin/bash

# Source the base script
source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Backup the sshd_config file
backup_file "/etc/ssh/sshd_config"

# Disable root login and password authentication
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
enable_service "ssh"
