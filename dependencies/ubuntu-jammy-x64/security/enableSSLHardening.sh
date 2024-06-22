#!/bin/bash

set -e

# Additional SSH hardening settings
sudo sed -i 's/^#AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config
sudo sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sudo sed -i 's/^#ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config

echo "SSH hardening completed."
