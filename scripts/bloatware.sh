#!/bin/bash

main() {
  BLOATWARE_PACKAGES=(
    # Games
    "aisleriot" "five-or-more" "four-in-a-row" "gnome-2048" "gnome-chess" "gnome-klotski" "gnome-mahjongg" "gnome-mines" "gnome-nibbles" "gnome-robots" "gnome-sudoku" "gnome-taquin" "gnome-tetravex" "hitori" "iagno" "lightsoff" "pegsolitaire" "quadrapassel" "swell-foop" "tali"
    # Apps
    "apport" "baobab" "brltty" "cheese" "cmake" "decibels" "deja-dup" "duplicity" "empathy" "eos-apps-info" "eos-log-tool" "epiphany" "evince" "example-content" "gdebi*" "gnome-abrt" "gnome-boxes" "gnome-calendar" "gnome-characters" "gnome-clocks" "gnome-console" "gnome-contacts" "gnome-font-viewer" "gnome-logs" "gnome-maps" "gnome-music" "gnome-nettool" "gnome-screensaver" "gnome-snapshot" "gnome-sound-recorder" "gnome-tour" "gnome-usage" "gnome-video-effects" "gnome-weather" "imagemagick*" "landscape-common" "libreoffice*" "libsane" "mcp-account-manager-uoa" "mediawriter" "meld" "popularity-contest" "python3-uno" "reflector-simple" "rhythmbox" "sane-utils" "seahorse" "shotwell" "simple-scan" "snapshot" "stoken" "telepathy-*" "thunderbird" "tilix" "totem" "transmission-gtk" "ubuntu-report" "unity-scope-*" "usb-creator-gtk" "whoopsie" "xterm" "yelp"
  )
  for PACKAGE in "${BLOATWARE_PACKAGES[@]}"; do
    echo "Removing $PACKAGE..."
    case $DETECTED_DISTRO in
    "debian")
      sudo apt purge -y --autoremove "$PACKAGE"
      ;;
    "arch")
      yay -Rcnssu --noconfirm "$PACKAGE"
      ;;
    "fedora")
      sudo dnf remove -y "$PACKAGE"
      ;;
    esac
  done
  case $DETECTED_DISTRO in
  "debian")
    sudo apt install -y --fix-broken
    sudo dpkg --configure -a
    sudo apt autoremove --purge -y
    sudo apt clean
    sudo apt autoclean
    ;;
  "arch")
    yay -Scc --noconfirm
    ;;
  "fedora")
    sudo dnf autoremove -y
    sudo dnf clean all
    ;;
  "mac")
    brew cleanup
    ;;
  esac
  for APP_ICON in nm-connection-editor info bssh bvnc avahi-discover org.freedesktop.MalcontentControl qv4l2 qvidcap assistant qdbusviewer linguist designer htop nvtop vim; do
    if [ -f "/usr/share/applications/$APP_ICON.desktop" ]; then
      sudo mv -v "/usr/share/applications/$APP_ICON.desktop" "/usr/share/applications/$APP_ICON.back"
    fi
  done
  flatpak uninstall --unused || true
  sudo truncate -s 0 /var/log/**/*.log ~/.local/share/xorg/*.log
  sudo rm -rfv /tmp/* ~/.viminfo ~/.local/share/Trash/* ~/.cache/mozilla/firefox/* ~/.cache/evolution/* ~/.cache/thumbnails/* ~/.local/share/recently-used.xbel ~/.local/share/gnome-shell/application_state ~/.local/share/gnome-shell/favorite-apps ~/.local/share/gnome-shell/searches/* ~/.local/share/gnome-shell/overview/*
  sudo docker system prune -a -f
  tracker3 reset -s -r
}

main "$@"
