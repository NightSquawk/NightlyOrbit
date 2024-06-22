# Function to check if Tailscale is running
check_tailscale_running() {
    if sudo tailscale status | grep -q "Tailscale service is not running"; then
        return 1
    fi
    return 0
}