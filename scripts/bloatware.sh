#!/bin/bash

remove_snap() {
  for pkg in $(snap list | grep -v core | grep -v snapd | grep -v bare | awk 'NR>1 {print $1}'); do
    sudo snap remove --purge "$pkg";
  done
  for pkg in $(snap list | awk 'NR>1 {print $1}'); do
    sudo snap remove --purge "$pkg";
  done
  remove_packages "snapd"
  if command -v gnome-shell >/dev/null 2>&1; then
    remove_packages "gnome-software-plugin-snap"
  fi
  if [ "$DETECTED_DISTRO" == "debian" ]; then
    sudo apt-mark hold snapd
    echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/no-snap.pref
    sudo chown root:root /etc/apt/preferences.d/no-snap.pref
    # prefer apt for install firefox
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
  fi
  sudo rm -rfv ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd /root/snap
}

remove_flatpak() {
  flatpak list --app | awk '{print $1}' | while read pkg; do
    flatpak uninstall --delete-data -y "$pkg"
  done
  remove_packages "flatpak"
}

stop_services() {
  if [ "$IS_WSL" == "true" ]; then
    # Cloud-Init Services (for cloud VMs only)
    sudo systemctl disable --now cloud-config cloud-final cloud-init-local cloud-init
    # Ubuntu Pro Services
    sudo systemctl disable --now ubuntu-advantage ua-reboot-cmds wsl-pro
    # Background & Maintenance Services
    sudo systemctl disable --now cron unattended-upgrades e2scrub_reap
    # Docker
    sudo systemctl disable --now docker docker.socket containerd
  fi
}

main() {
  remove_snap
  remove_flatpak
  stop_services

  if [ "$DETECTED_DISTRO" != "mac" ]; then
    # Games
    remove_packages "aisleriot five-or-more four-in-a-row gnome-2048 gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff pegsolitaire quadrapassel showtime swell-foop tali"
    # Apps
    remove_packages "alacritty apport baobab brltty cheese cmake decibels deja-dup duplicity empathy eos-apps-info eos-log-tool epiphany evince evolution example-content gdebi* gnome-abrt gnome-calendar gnome-characters gnome-clocks gnome-console gnome-contacts gnome-font-viewer gnome-logs gnome-maps gnome-music gnome-nettool gnome-screensaver gnome-snapshot gnome-sound-recorder gnome-tour gnome-usage gnome-video-effects gnome-weather imagemagick* landscape-common libreoffice* libsane mcp-account-manager-uoa mediawriter meld papers popularity-contest ptyxis python3-uno reflector-simple rhythmbox sane-utils seahorse shotwell simple-scan snapshot stoken sysprof telepathy-* thunderbird tilix totem transmission-gtk ubuntu-report unity-scope-* usb-creator-gtk whoopsie xterm yelp"

    if [ "$IS_WSL" == "true" ]; then
      remove_snap "fwupd ubuntu-drivers-common"
    fi
  fi

  case "$DETECTED_DISTRO" in
  "debian")
    sudo apt install -y --fix-broken
    sudo dpkg --configure -a
    sudo apt autoremove --purge -y
    sudo apt clean
    sudo apt autoclean
    sudo apt update
    ;;
  "arch")
    yay -Ycc --noconfirm
    yay -Scc --noconfirm
    yay -Sy
    ;;
  "fedora")
    sudo dnf autoremove -y
    sudo dnf clean all
    sudo dnf update -y
    ;;
  "mac")
    brew cleanup
    brew update
    ;;
  esac
  for APP_ICON in nm-connection-editor info micro bssh bvnc avahi-discover org.freedesktop.MalcontentControl qv4l2 qvidcap assistant qdbusviewer linguist designer electron37 cmake-gui; do
    if [ -f "/usr/share/applications/$APP_ICON.desktop" ]; then
      sudo mv -v "/usr/share/applications/$APP_ICON.desktop" "/usr/share/applications/$APP_ICON.back"
    fi
  done
  if command -v flatpak >/dev/null 2>&1; then
    flatpak uninstall --unused
  fi
  sudo truncate -s 0 /var/log/**/*.log ~/.local/share/xorg/*.log
  sudo rm -rfv /tmp/* ~/.viminfo ~/.wget-hsts ~/.local/share/Trash/* ~/.cache/mozilla/firefox/* ~/.cache/evolution/* ~/.cache/thumbnails/* ~/.local/share/recently-used.xbel ~/.local/share/gnome-shell/application_state ~/.local/share/gnome-shell/favorite-apps ~/.local/share/gnome-shell/searches/* ~/.local/share/gnome-shell/overview/* /var/cache/pacman/pkg/*
  sudo docker system prune -a -f
  if command -v tracker3 >/dev/null 2>&1; then
    tracker3 reset -s -r
  fi
  if [ "$IS_WSL" != "true" ]; then
    ensure_packages "gnome-terminal"
  fi
}

main "$@"
