#!/bin/bash

main() {
  SERVICES_OPTIONS=(
    "AdGuard" "Samba" "Jellyfin"
  )

  select SERVICES_CHOICE in "${SERVICES_OPTIONS[@]}"; do
    echo "Installing $SERVICES_CHOICE..."
    case $SERVICES_CHOICE in
    "AdGuard")
      wget -cO- "https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh" | sh -s -- -v
      ;;
    "Samba")
      case $DETECTED_DISTRO in
      "debian")
        sudo apt install -y samba
        ;;
      "arch")
        yay -S --noconfirm --needed --removemake --cleanafter samba
        ;;
      "fedora")
        sudo dnf install -y samba
        ;;
      "mac")
        brew install --cask samba
        ;;
      esac
      echo "Enter Your Samba User: "
      read -r SMB_USER
      sudo useradd "$SMB_USER"
      sudo passwd "$SMB_USER"
      sudo smbpasswd -a "$SMB_USER"
      sudo usermod -g smbgroup "$SMB_USER"
      echo -e "[share]\n    comment = Share\n    path = /media\n    browsable = yes\n    guest ok = yes\n    read only = no\n    create mask = 0755" | sudo tee -a /etc/samba/smb.conf
      sudo vim /etc/samba/smb.conf
      case $DETECTED_DISTRO in
      "debian")
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
      case $DETECTED_DISTRO in
      "debian")
        curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash
        ;;
      "arch")
        yay -S --noconfirm --needed --removemake --cleanafter jellyfin-server jellyfin-web
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
