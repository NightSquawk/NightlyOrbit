#!/bin/bash
# cleaner.sh

REPO_DIR="NightlyOrbit"
SETUP_FILE="setup.sh"

# Check if the repository directory exists
if [ -d "$REPO_DIR" ]; then
  # Remove the repository directory
  rm -rf "$REPO_DIR"
  echo "Deleted the $REPO_DIR directory successfully!"
else
  echo "Directory $REPO_DIR does not exist."
fi

# Check if the setup file exists
if [ -f "$SETUP_FILE" ]; then
  # Remove the setup file
  rm "$SETUP_FILE"
  echo "Deleted the $SETUP_FILE file successfully!"
else
  echo "File $SETUP_FILE does not exist."
fi

echo "Cleaner script executed successfully!"