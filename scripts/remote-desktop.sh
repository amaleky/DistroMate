#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id AnyDeskSoftwareGmbH.AnyDesk
  else
    case "$DETECTED_DISTRO" in
    "debian")
      BASE_URL="https://download.anydesk.com/linux/"
      LATEST_DEB=$(wget -cO- $BASE_URL | grep -o 'href="[^"]*_amd64.deb"' | sed 's/href="//' | sed 's/"//' | head -1)
      wget -cO /tmp/anydesk.deb "${BASE_URL}${LATEST_DEB}"
      ensure_packages "/tmp/anydesk.deb"
      rm -rfv /tmp/anydesk.deb
      ;;
    "arch")
      ensure_packages "anydesk-bin"
      ;;
    "fedora")
      BASE_URL="https://download.anydesk.com/linux/"
      LATEST_RPM=$(wget -cO- $BASE_URL | grep -o 'href="[^"]*x86_64.rpm"' | sed 's/href="//' | sed 's/"//' | head -1)
      wget -cO /tmp/anydesk.rpm "${BASE_URL}${LATEST_RPM}"
      ensure_packages "/tmp/anydesk.rpm"
      rm -rfv /tmp/anydesk.rpm
      ;;
    "mac")
      ensure_packages "anydesk" "--cask"
      ;;
    esac
    sudo systemctl disable anydesk
  fi
}

main "$@"
