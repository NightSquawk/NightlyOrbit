#!/bin/bash

set -e

# Source base.sh to use its functions
source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Function to send a web hook message
send_webhook_message() {
    local webhook_url=$1
    local message=$2
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$message\"}" "$webhook_url" || handle_error "Failed to send webhook message"
}

# Prompt for web hook URL
webhook_url=$(prompt_input "Enter the web hook URL: ")

# Prompt for message to send
webhook_message=$(prompt_input "Enter the message to send: ")

# Send the message
send_webhook_message "$webhook_url" "$webhook_message"

# Save the web hook URL to system variables
if [[ -f ~/.bashrc ]]; then
    echo "export WEBHOOK_URL=\"$webhook_url\"" >> ~/.bashrc
    source ~/.bashrc
elif [[ -f ~/.zshrc ]]; then
    echo "export WEBHOOK_URL=\"$webhook_url\"" >> ~/.zshrc
    source ~/.zshrc
else
    echo "Unable to find suitable shell configuration file to save the webhook URL."
fi

echo "Web hook URL saved to system variables and message sent successfully!"
