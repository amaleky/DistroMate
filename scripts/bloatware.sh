#!/bin/bash

main() {
  if [ "$IS_WSL" == "true" ]; then
    for pkg in $(snap list | grep -v core | grep -v snapd | grep -v bare | awk 'NR>1 {print $1}'); do sudo snap remove --purge "$pkg"; done
    for pkg in $(snap list | awk 'NR>1 {print $1}'); do sudo snap remove --purge "$pkg"; done
    remove_packages "snapd"
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
      remove_packages "gnome-software-plugin-snap"
    fi
    case "$DETECTED_DISTRO" in
    "debian")
      sudo apt-mark hold snapd
      echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/no-snap.pref
      sudo chown root:root /etc/apt/preferences.d/no-snap.pref
      ;;
    esac
    sudo rm -rfv ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd /root/snap
  fi

  if [ "$DETECTED_DISTRO" != "mac" ]; then
    # Games
    remove_packages "aisleriot five-or-more four-in-a-row gnome-2048 gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff pegsolitaire quadrapassel showtime swell-foop tali"
    # Apps
    remove_packages "apport alacritty baobab brltty cheese cmake decibels deja-dup duplicity empathy evolution eos-apps-info eos-log-tool epiphany evince example-content gdebi* gnome-abrt gnome-calendar gnome-characters gnome-clocks gnome-console gnome-contacts gnome-font-viewer gnome-logs gnome-maps gnome-music gnome-nettool gnome-screensaver gnome-snapshot gnome-sound-recorder gnome-tour gnome-usage gnome-video-effects gnome-weather imagemagick* landscape-common libreoffice* libsane mcp-account-manager-uoa mediawriter meld popularity-contest python3-uno reflector-simple rhythmbox sane-utils seahorse shotwell simple-scan snapshot stoken telepathy-* thunderbird tilix totem transmission-gtk ubuntu-report unity-scope-* usb-creator-gtk whoopsie xterm yelp"
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
  for APP_ICON in nm-connection-editor info micro bssh bvnc avahi-discover org.freedesktop.MalcontentControl qv4l2 qvidcap assistant qdbusviewer linguist designer htop nvtop vim electron37 cmake-gui; do
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
  tracker3 reset -s -r
}

main "$@"
