#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id Tonec.InternetDownloadManager
  else
    case $DETECTED_DISTRO in
    "debian" | "arch" | "fedora")
      wget -cO- "https://raw.githubusercontent.com/amir1376/ab-download-manager/master/scripts/install.sh" | bash
      ;;
    "mac")
      brew install --cask free-download-manager
      ;;
    esac
  fi
}

main "$@"
