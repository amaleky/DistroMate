#!/bin/sh

main() {
  while :; do
    printf '%s\n' '1) AnyDesk'
    printf '%s\n' '2) Remmina'
    printf '%s' 'Enter your choice: '
    IFS= read -r PROGRAMMING_CHOICE_INDEX || return 0
    case "$PROGRAMMING_CHOICE_INDEX" in
      1) PROGRAMMING_CHOICE="AnyDesk" ;;
      2) PROGRAMMING_CHOICE="Remmina" ;;
      *) printf '%s\n' "Invalid option $PROGRAMMING_CHOICE_INDEX" >&2; continue ;;
    esac
    info "Installing $PROGRAMMING_CHOICE..."
    case "$PROGRAMMING_CHOICE" in
    "AnyDesk")
      if [ "$IS_WSL" = "true" ]; then
        winget.exe install -e --id AnyDeskSoftwareGmbH.AnyDesk
      else
        case "$DETECTED_DISTRO" in
        "debian")
          BASE_URL="https://deb.anydesk.com/"
          LATEST_DEB="$(curl -fsSL "${BASE_URL}dists/all/main/binary-$DEB_ARCH/Packages" | awk '/^Filename:/{print $2; exit}')"
          curl -fL -o "/tmp/anydesk.deb" "${BASE_URL}${LATEST_DEB}"
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
