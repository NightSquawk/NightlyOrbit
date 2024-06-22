#!/bin/bash

# Source the base script
source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Install UFW if not installed
install_package "ufw"

# Default policies
configure_firewall "default deny incoming"
configure_firewall "default allow outgoing"

# Allow SSH
configure_firewall "allow ssh"

# Enable the firewall
sudo ufw enable || handle_error "Failed to enable UFW"

echo "Firewall setup completed."
