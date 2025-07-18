#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id Oracle.VirtualBox
  else
    case $DETECTED_DISTRO in
    "debian")
      sudo apt install -y virtualbox virtualbox-dkms
      ;;
    "arch")
      yay -S --noconfirm --needed --removemake --cleanafter virtualbox virtualbox-host-dkms
      ;;
    "fedora")
      sudo dnf install -y VirtualBox
      ;;
    "mac")
      brew install --cask virtualbox
      ;;
    esac
  fi
}

main "$@"
