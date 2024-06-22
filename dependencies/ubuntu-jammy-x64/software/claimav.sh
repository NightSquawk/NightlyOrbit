# clamav.sh
#!/bin/bash

sudo apt-get update
sudo apt-get install -y clamav clamav-daemon

# Update ClamAV database
sudo freshclam

# Enable and start the ClamAV daemon
sudo systemctl enable clamav-daemon
sudo systemctl start clamav-daemon

echo "ClamAV installation and configuration completed."
