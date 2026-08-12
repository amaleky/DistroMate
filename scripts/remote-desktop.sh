#!/bin/bash

main() {
  PROGRAMMING_OPTIONS=(
    "AnyDesk" "Remmina"
  )

  select PROGRAMMING_CHOICE in "${PROGRAMMING_OPTIONS[@]}"; do
    info "Installing $PROGRAMMING_CHOICE..."
    case "$PROGRAMMING_CHOICE" in
    "AnyDesk")
      if [ "$IS_WSL" == "true" ]; then
        winget.exe install -e --id AnyDeskSoftwareGmbH.AnyDesk
      else
        case "$DETECTED_DISTRO" in
        "debian")
          BASE_URL="https://deb.anydesk.com/"
          LATEST_DEB="$(wget -cO- "${BASE_URL}dists/all/main/binary-$DEB_ARCH/Packages" | awk '/^Filename:/{print $2; exit}')"
          wget -cO "/tmp/anydesk.deb" "${BASE_URL}${LATEST_DEB}"
          ensure_packages "/tmp/anydesk.deb"
          rm -rfv "/tmp/anydesk.deb"
          ;;
        "arch")
          ensure_packages "anydesk-bin"
          ;;
        "fedora")
          sudo tee /etc/yum.repos.d/anydesk.repo << EOF
[anydesk]
name=AnyDesk Fedora - $RPM_ARCH
baseurl=https://rpm.anydesk.com/$RPM_ARCH/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF
          ensure_packages "anydesk"
          ;;
        "mac")
          ensure_packages "anydesk" "--cask"
          ;;
        esac
        sudo systemctl disable anydesk
      fi
      ;;
    "Remmina")
      case "$DETECTED_DISTRO" in
      "debian" | "arch" | "fedora")
        ensure_packages "remmina"
        ;;
      esac
      ;;
    esac
    menu
  done
}

main "$@"
