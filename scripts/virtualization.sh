#!/bin/bash

main() {
  if [ "$IS_WSL" == "true" ]; then
    winget.exe install -e --id Oracle.VirtualBox
  else
    case "$DETECTED_DISTRO" in
    "debian")
      ensure_packages "gnome-boxes"
      ;;
    "arch")
      ensure_packages "gnome-boxes"
      ;;
    "fedora")
      ensure_packages "gnome-boxes"
      ;;
    "mac")
      ensure_packages "virtualbox" "--cask"
      ;;
    esac
  fi
}

main "$@"
