#!/bin/bash

main() {
  case "$DETECTED_DISTRO" in
  "debian")
    if command -v modernize-sources >/dev/null 2>&1; then
      sudo apt modernize-sources -y
    fi
    sudo apt update
    sudo apt dist-upgrade -y
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
  if [ "$IS_WSL" == "true" ]; then
    winget.exe upgrade --all
  fi
}

main "$@"
