#!/bin/bash

main() {
  case "$DETECTED_DISTRO" in
  "debian")
    if command -v modernize-sources >/dev/null 2>&1; then
      sudo apt modernize-sources -y
    fi
    sudo apt update
    sudo apt dist-upgrade -y
    OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$OS_ID" in
    "ubuntu")
      sudo do-release-upgrade
      ;;
    "pop")
      sudo pop-upgrade release upgrade
      ;;
    esac
    ;;
  "arch")
    yay -Syyuu --noconfirm --removemake --cleanafter
    ;;
  "fedora")
    sudo dnf update -y
    ;;
  "mac")
    brew update
    brew upgrade
    ;;
  esac
  if command -v snap >/dev/null 2>&1; then
    sudo snap refresh
  fi
  if command -v flatpak >/dev/null 2>&1; then
    sudo flatpak update
  fi
  if [ -n "$IS_WSL" ]; then
    winget.exe upgrade --all
  fi
}

main "$@"
