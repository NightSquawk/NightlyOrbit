#!/bin/bash
# autoupdate.sh
# This script enables automatic updates for packages and the distribution.

set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Update package lists and upgrade all packages
apt-get update -y
apt-get upgrade -y

# Install unattended-upgrades if not already installed
if ! dpkg -l | grep -q unattended-upgrades; then
    apt-get install unattended-upgrades -y
fi

# Enable the unattended-upgrades service
dpkg-reconfigure -plow unattended-upgrades

# Configure automatic updates
cat <<EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Configure unattended-upgrades for both security and other updates
cat <<EOF > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Origins-Pattern {
        "o=Debian,a=stable";
        "o=Debian,a=stable-updates";
        "o=Debian-Security,a=stable";
        "o=Ubuntu,a=$(lsb_release -cs)";
        "o=Ubuntu,a=$(lsb_release -cs)-updates";
        "o=Ubuntu,a=$(lsb_release -cs)-security";
        "o=UbuntuESMApps,a=$(lsb_release -cs)";
        "o=UbuntuESM,a=$(lsb_release -cs)";
};

Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

echo "Automatic updates have been enabled and configured."

# Start the unattended-upgrades service
systemctl enable unattended-upgrades
systemctl start unattended-upgrades
