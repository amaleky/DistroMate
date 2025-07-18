#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id OBSProject.OBSStudio
  else
    case $DETECTED_DISTRO in
    "debian")
      sudo apt install -y obs-studio
      ;;
    "arch")
      yay -S --noconfirm --needed --removemake --cleanafter obs-studio
      ;;
    "fedora")
      sudo dnf install -y obs-studio
      ;;
    "mac")
      brew install --cask obs
      ;;
    esac
  fi
}

main "$@"
