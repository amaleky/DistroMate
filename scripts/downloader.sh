#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id SoftDeluxe.FreeDownloadManager
  else
    case "$DETECTED_DISTRO" in
    "debian")
      wget -cO "/tmp/freedownloadmanager.deb" "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb"
      ensure_packages "/tmp/freedownloadmanager.deb"
      rm -rfv "/tmp/freedownloadmanager.deb"
      ;;
    "arch")
      ensure_packages "freedownloadmanager"
      ;;
    "mac")
      ensure_packages "free-download-manager" "--cask"
      ;;
    esac
  fi
}

main "$@"
