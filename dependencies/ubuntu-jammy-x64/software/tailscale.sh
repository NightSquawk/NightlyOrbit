#!/bin/bash

set -e

# Source base.sh to use its functions
source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Function to check if Tailscale is running
check_tailscale_running() {
    if sudo tailscale status | grep -q "Tailscale service is not running"; then
        return 1
    fi
    return 0
}

# Function to install Tailscale
install_tailscale() {
    if ! check_installed "tailscale"; then
        curl -fsSL https://tailscale.com/install.sh | sh || handle_error "Failed to install Tailscale"
    else
        echo "Tailscale is already installed."
    fi
}

# Function to start Tailscale and show a QR code
start_tailscale() {
    sudo tailscale up || handle_error "Failed to start Tailscale"
    if check_tailscale_running; then
        auth_url=$(sudo tailscale up --qr | grep "To authenticate, visit:" | awk '{print $4}')
        qrencode -t ansiutf8 "$auth_url" || handle_error "Failed to generate QR code"
        echo -e "\nScan the above QR code to link your device."
    else
        handle_error "Tailscale service is not running"
    fi
}

# Install Tailscale
install_tailscale

# Ensure qrencode is installed for generating QR codes
install_package "qrencode"

# Start Tailscale and show QR code
start_tailscale

echo "Tailscale setup completed successfully!"
