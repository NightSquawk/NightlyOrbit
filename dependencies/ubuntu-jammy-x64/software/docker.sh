# Install ca-certificates and curl if not already installed
install_package "ca-certificates"
install_package "curl"

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings || handle_error "Failed to create directory for Docker GPG key"
sudo curl -fsSL https://download.docker.com/linux/"$ID"/gpg -o /etc/apt/keyrings/docker.asc || handle_error "Failed to download Docker GPG key"
sudo chmod a+r /etc/apt/keyrings/docker.asc || handle_error "Failed to set permissions for Docker GPG key"

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || handle_error "Failed to add Docker repository to sources"

sudo apt-get update || handle_error "Failed to update package lists"

# Install the Docker packages
install_package "docker-ce"
install_package "docker-ce-cli"
install_package "containerd.io"
install_package "docker-buildx-plugin"
install_package "docker-compose-plugin"