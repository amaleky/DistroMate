#!/bin/sh

main() {
  while :; do
    printf '%s\n' '1) AdGuard'
    printf '%s\n' '2) Samba'
    printf '%s\n' '3) Jellyfin'
    printf '%s' 'Enter your choice: '
    IFS= read -r SERVICES_CHOICE_INDEX || return 0
    case "$SERVICES_CHOICE_INDEX" in
      1) SERVICES_CHOICE="AdGuard" ;;
      2) SERVICES_CHOICE="Samba" ;;
      3) SERVICES_CHOICE="Jellyfin" ;;
      *) printf '%s\n' "Invalid option $SERVICES_CHOICE_INDEX" >&2; continue ;;
    esac
    info "Installing $SERVICES_CHOICE..."
    case "$SERVICES_CHOICE" in
    "AdGuard")
      curl -fsSL "https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh" | sh -s -- -v
      ;;
    "Samba")
      case "$DETECTED_DISTRO" in
      "mac")
        ensure_packages "samba" "--cask"
        ;;
      *)
        ensure_packages "samba"
        ;;
      esac
      info "Enter Your Samba User: "
      read -r SMB_USER
      sudo useradd "$SMB_USER"
      sudo passwd "$SMB_USER"
      sudo smbpasswd -a "$SMB_USER"
      sudo usermod -g smbgroup "$SMB_USER"
      cat <<'EOF' | sudo tee -a /etc/samba/smb.conf
[share]
    comment = Share
    path = /media
    browsable = yes
    guest ok = yes
    read only = no
    create mask = 0755
EOF
      sudo vim /etc/samba/smb.conf
      case "$DETECTED_DISTRO" in
      "debian")
        ensure_packages "wsdd"
        sudo systemctl restart smbd nmbd
        sudo systemctl enable smbd
        ;;
      "arch" | "fedora")
        sudo systemctl restart smb nmb
        sudo systemctl enable smb nmb
        ;;
      "mac")
        sudo systemctl enable smb
        ;;
      esac
      ;;
    "Jellyfin")
      case "$DETECTED_DISTRO" in
      "debian")
        curl https://repo.jellyfin.org/install-debuntu.sh | sudo sh
        ;;
      "arch")
        ensure_packages "jellyfin-server jellyfin-web"
        ;;
      esac
      sudo usermod -aG "$USER" jellyfin
      sudo chmod -R o+rx /media/
      ;;
    esac
    menu
  done
}

main "$@"
