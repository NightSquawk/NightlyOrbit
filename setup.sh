#!/bin/bash
# Copyright (c) NightSquawk Tech
# SPDX-License-Identifier: BSD-3-Clause
#
# This script detects the current operating system,
# downloads the appropriate modules, and attempts to
# set up the programs with the best practices.
#
# Portions of this script are derived from the Tailscale
# install script available at:
# https://tailscale.com/install.sh
#
# The original Tailscale script is licensed under the BSD-3-Clause license:
#
# Copyright (c) Tailscale Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

set -eu

# All the code is wrapped in a main function that gets called at the
# bottom of the file, so that a truncated partial download doesn't end
# up executing half a script.

main() {

  # Thess variables can be modified to change the setup behavior
  # If you clone the repository to a different location, you can
  # change the repo_url to point to your repository.
  repo_owner="NightSquawk"
  repo_name="NightlyOrbit"

  setup_type="default"  # Change this to "custom" to select modules

  # DO NOT CHANGE BELOW THIS LINE
  OS=""
  VERSION=""
  PACKAGETYPE=""
  APT_KEY_TYPE="" # Only for apt-based distros
  APT_SYSTEMCTL_START=false # Only needs to be true for Kali

  # Get track from command-line argument, default to "stable"
  TRACK="${1:-stable}"

  case "$TRACK" in
    stable|development)
      ;;
    *)
      echo "unsupported track $TRACK"
      exit 1
      ;;
  esac

  repo_url="https://github.com/${repo_owner}/${repo_name}"
  repo_raw="https://raw.githubusercontent.com/${repo_owner}/${repo_name}/${TRACK}"

  repo_dir=$(basename "$repo_url" .git)

  # Expected directory structure
  # /dependencies/base.sh or /dependencies/other/cleaner.sh
  base_script="base.sh"
  dependencies_dir="dependencies"
  dependencies=(
  "other/example.sh"
  )

  if [ -f /etc/os-release ]; then
      # /etc/os-release populates a number of shell variables. We care about the following:
      #  - ID: the short name of the OS (e.g. "debian", "freebsd")
      #  - VERSION_ID: the numeric release version for the OS, if any (e.g. "18.04")
      #  - VERSION_CODENAME: the codename of the OS release, if any (e.g. "buster")
      #  - UBUNTU_CODENAME: if it exists, use instead of VERSION_CODENAME

      . /etc/os-release

      # Detect the architecture
      ARCHITECTURE=$(uname -m)
      case "$ARCHITECTURE" in
          x86_64)
              ARCH="x64"
              ;;
          i386|i686)
              ARCH="x86"
              ;;
          armv7l)
              ARCH="armhf"
              ;;
          armv6l|aarch64)
              ARCH="arm"
              ;;
          *)
              ARCH="unknown"
              ;;
      esac

      case "$ID" in
        ubuntu|pop|neon|zorin|tuxedo)
          OS="ubuntu"
          if [ "${UBUNTU_CODENAME:-}" != "" ]; then
              VERSION="$UBUNTU_CODENAME"
          else
              VERSION="$VERSION_CODENAME"
          fi
          PACKAGETYPE="apt"
          # Third-party keyrings became the preferred method of
          # installation in Ubuntu 20.04.
          if expr "$VERSION_ID" : "2.*" >/dev/null; then
            APT_KEY_TYPE="keyring"
          else
            APT_KEY_TYPE="legacy"
          fi
          ;;
        debian)
          OS="$ID"
          VERSION="$VERSION_CODENAME"
          PACKAGETYPE="apt"
          # Third-party keyrings became the preferred method of
          # installation in Debian 11 (Bullseye).
          if [ -z "${VERSION_ID:-}" ]; then
            # rolling release. If you haven't kept current, that's on you.
            APT_KEY_TYPE="keyring"
          elif [ "$VERSION_ID" -lt 11 ]; then
            APT_KEY_TYPE="legacy"
          else
            APT_KEY_TYPE="keyring"
          fi
          ;;
      esac
    fi

  # Ideally we want to use curl, but on some installs we
  # only have wget. Detect and use what's available.
  CURL=
  if type curl >/dev/null; then
    CURL="curl -fsSL"
  elif type wget >/dev/null; then
    CURL="wget -q -O-"
  fi
  if [ -z "$CURL" ]; then
    echo "The installer needs either curl or wget to download files."
    echo "Please install either curl or wget to proceed."
    exit 1
  fi

  TEST_URL="https://example.com/"
  RC=0
  TEST_OUT=$($CURL "$TEST_URL" 2>&1) || RC=$?
  if [ $RC != 0 ]; then
    echo "The installer cannot reach $TEST_URL"
    echo "Please make sure that your machine has internet access."
    echo "Test output:"
    echo "$TEST_OUT"
    exit 1
  fi

  # Print detected values (optional)
  clear
  echo -e "Installing using the following values:\n"
  echo "Operating System: $OS"
  echo "Version: $VERSION"
  echo "Package Type: $PACKAGETYPE"
  echo "Architecture: $ARCH"
  echo "TRACK: $TRACK"

  # Step 2: having detected an OS we support, is it one of the
  # versions we support?
  OS_UNSUPPORTED=
  case "$OS" in
    ubuntu|debian|raspbian|centos|oracle|rhel|amazon-linux|opensuse|photon)
      # Check with the package server whether a given version is supported.
      URL="${repo_raw}/${dependencies_dir}/${OS}-${VERSION}-${ARCH}/supported"

      echo -e "\nChecking $URL\n"
      $CURL "$URL" 2> /dev/null | grep -q OK || OS_UNSUPPORTED=1
      ;;
    other-linux)
      OS_UNSUPPORTED=1
      ;;
    *)
      OS_UNSUPPORTED=1
      ;;
  esac
  if [ "$OS_UNSUPPORTED" = "1" ]; then
    case "$OS" in
      other-linux)
        echo "Couldn't determine what kind of Linux is running."
        ;;
      "")
        echo "Couldn't determine what operating system you're running."
        ;;
      *)
#        clear
        echo "$OS $VERSION isn't supported by this script yet."
        ;;
    esac
    echo
    echo "If you'd like us to support your system better, please open an issue on GitHub"
    echo "and tell us what OS you're running."
    echo
    echo "Please include the following information we gathered from your system:"
    echo
    echo "OS=$OS"
    echo "VERSION=$VERSION"
    echo "PACKAGETYPE=$PACKAGETYPE"
    if type uname >/dev/null 2>&1; then
      echo "UNAME=$(uname -a)"
    else
      echo "UNAME="
    fi
    echo
    if [ -f /etc/os-release ]; then
      cat /etc/os-release
    else
      echo "No /etc/os-release"
    fi
    exit 1
  fi

  # Step 3: work out if we can run privileged commands, and if so,
  # how.
  CAN_ROOT=
  if [ "$(id -u)" = 0 ]; then
    CAN_ROOT=1
  elif type sudo >/dev/null; then
    CAN_ROOT=1
  elif type doas >/dev/null; then
    CAN_ROOT=1
  fi
  if [ "$CAN_ROOT" != "1" ]; then
    echo "This installer needs to run commands as root."
    echo "We tried looking for 'sudo' and 'doas', but couldn't find them."
    echo "Either re-run this script as root, or set up sudo/doas."
    exit 1
  fi

  # Function to include dependencies
  includeDependencies() {
      local -n deps=$1
      for script in "${deps[@]}"; do
          source "${current_dir}/${dependencies_dir}/${script}"
      done
  }

  # Function to prompt user for module selection
  prompt_for_modules() {
      local -n deps=$1
      local disable_list=()

      echo "Select modules to disable (enter 'x' to disable, leave blank to enable):"
      for script in "${deps[@]}"; do
          read -r -p "[ ] $script " response
          if [[ "$response" =~ ^[Xx]$ ]]; then
              disable_list+=("$script")
          fi
      done

      # Remove disabled modules from the list
      for disable in "${disable_list[@]}"; do
          deps=("${deps[@]/$disable}")
      done
  }

  # Setup function
  setup() {
      local type=$1

      if [[ "$type" == "default" ]]; then
          dependencies=(
              "security/disableRootLoginPWD.sh"
              "security/enableUFW.sh"
          )
      fi

      # Clone the repository
      if [[ ! -d "$repo_dir" ]]; then
          echo "Cloning repository..."
          git clone "$repo_url" "$repo_dir"
      fi

      # Navigate to the repository
      cd "$repo_dir"

      # Get the current directory
      current_dir=$(pwd)

      echo "Current directory: $current_dir"

      # Source the base script
      if [[ -f "${dependencies_dir}/${base_script}" ]]; then
          echo "Sourcing ${current_dir}/${dependencies_dir}/${base_script}"
          source "${dependencies_dir}/${base_script}"
      else
          echo "Sourcing ${dependencies_dir}/${base_script}"
          echo "Error: ${base_script} not found in ${dependencies_dir}"
          exit 1
      fi
  }

  # Execute setup with the specified setup type
  setup "$setup_type"

  # If setup_type is custom, prompt for module selection
  if [[ "$setup_type" == "custom" ]]; then
      prompt_for_modules dependencies
  fi

  # Include dependencies
  includeDependencies dependencies

  echo "Setup completed."
}

main "$@"