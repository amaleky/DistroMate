#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id Oracle.VirtualBox
  else
    case "$DETECTED_DISTRO" in
    "debian")
      ensure_packages "virtualbox virtualbox-dkms"
      ;;
    "arch")
      ensure_packages "virtualbox virtualbox-host-dkms"
      ;;
    "fedora")
      ensure_packages "VirtualBox"
      ;;
    "mac")
      ensure_packages "virtualbox" "--cask"
      ;;
    esac
  fi
}

main "$@"
