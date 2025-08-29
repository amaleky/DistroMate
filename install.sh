#!/bin/bash
# DistroMate Installation Script
# Automates system setup and configuration
#
# Copyright (c) 2024 Alireza Maleky
# License: MIT
#
# Usage:
#   bash -c "$(wget -qO- https://raw.githubusercontent.com/amaleky/DistroMate/main/install.sh)"
#
# For more information, see the README.md

readonly REPO_URL="https://raw.githubusercontent.com/amaleky/DistroMate/main"
export REPO_URL

menu() {
  local PS3="Enter your choice [1-15]: "
  local options=("Upgrade" "Bloatware" "Recommended" "Driver" "Development" "Browser" "Player" "Downloader" "Virtualization" "RemoteDesktop" "ScreenRecorder" "Services" "Configs" "Quit")

  select opt in "${options[@]}"; do
    case "$REPLY" in
    1) source <(wget -qO- "${REPO_URL}/scripts/upgrade.sh") ;;
    2) source <(wget -qO- "${REPO_URL}/scripts/bloatware.sh") ;;
    3) source <(wget -qO- "${REPO_URL}/scripts/recommended.sh") ;;
    4) source <(wget -qO- "${REPO_URL}/scripts/driver.sh") ;;
    5) source <(wget -qO- "${REPO_URL}/scripts/development.sh") ;;
    6) source <(wget -qO- "${REPO_URL}/scripts/browser.sh") ;;
    7) source <(wget -qO- "${REPO_URL}/scripts/player.sh") ;;
    8) source <(wget -qO- "${REPO_URL}/scripts/downloader.sh") ;;
    9) source <(wget -qO- "${REPO_URL}/scripts/virtualization.sh") ;;
    10) source <(wget -qO- "${REPO_URL}/scripts/remote-desktop.sh") ;;
    11) source <(wget -qO- "${REPO_URL}/scripts/screen-recorder.sh") ;;
    12) source <(wget -qO- "${REPO_URL}/scripts/services.sh") ;;
    13) source <(wget -qO- "${REPO_URL}/scripts/configs.sh") ;;
    14)
      success "Exiting DistroMate installer. Thank you for using DistroMate!"
      exit 0
      ;;
    *) warning "Invalid option $REPLY" ;;
    esac
    echo # Add a blank line for readability
    menu
  done
}

source <(wget -qO- "${REPO_URL}/scripts/utils.sh")
menu "$@"
