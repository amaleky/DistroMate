#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id Tonec.InternetDownloadManager
  else
    case "$DETECTED_DISTRO" in
    "debian" | "fedora")
      wget -cO- "https://raw.githubusercontent.com/amir1376/ab-download-manager/master/scripts/install.sh" | bash
      ;;
    "arch")
      ensure_packages "abdownloadmanager-bin"
      ;;
    "mac")
      ensure_packages "free-download-manager" "--cask"
      ;;
    esac
  fi
}

main "$@"
