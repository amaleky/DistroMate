#!/bin/bash

main() {
  CONFIGS_OPTIONS=(
    "SSH" "Sudo" "Theme" "Extension"
  )

  select CONFIGS_CHOICE in "${CONFIGS_OPTIONS[@]}"; do
    info "Installing $CONFIGS_CHOICE..."
    case "$CONFIGS_CHOICE" in
    "SSH")
      case "$DETECTED_DISTRO" in
      "mac")
        ensure_packages "git" "--cask"
        ensure_packages "openssh-client" "--cask"
        ;;
      *)
        ensure_packages "git openssh-client"
        ;;
      esac
      if [ -f ~/.ssh/id_*.pub ]; then
        info "Changing SSH Keys Permission..."
        chmod -v 600 ~/.ssh/id_*
        chmod -v 644 ~/.ssh/id_*.pub
      else
        info "Enter Your SSH Email: "
        read SSH_EMAIL
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$SSH_EMAIL"
      fi
      if [ -z "$(git config --global user.name)" ]; then
        info "Enter Your GIT Name: "
        read GIT_NAME
        git config --global user.name "$GIT_NAME"
      fi
      if [ -z "$(git config --global user.email)" ]; then
        info "Enter Your GIT Email: "
        read GIT_EMAIL
        git config --global user.email "$GIT_EMAIL"
      fi
      sudo chown -Rv $USER:$USER ~/.ssh/
      for PUBLIC_KEY in ~/.ssh/*.pub; do
        info "This Is Your SSH Key ($PUBLIC_KEY): "
        cat "$PUBLIC_KEY"
      done
      ;;
    "Sudo")
      info "Unlocking Sudo Without Password..."
      sudo mkdir -p /etc/sudoers.d
      sudo rm -rfv /etc/sudoers.d/$USER
      sudo touch /etc/sudoers.d/$USER
      echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/$USER
      ;;
    "Theme")
      info "Installing dependencies for themes and icon packs..."
      case "$DETECTED_DISTRO" in
      "debian")
        ensure_packages "gtk2-engines-murrine gtk2-engines-pixbuf sassc"
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
          ensure_packages "gnome-tweaks gnome-shell gnome-shell-extensions gnome-themes-extra gnome-shell-extension-manager gnome-shell-extensions chrome-gnome-shell"
        fi
        ;;
      "arch")
        ensure_packages "gtk-engine-murrine gtk-engines ttf-mscorefonts-installer noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji ttf-ms-fonts vazirmatn-fonts ttf-jetbrains-mono"
        fc-cache --force
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
          ensure_packages "gnome-tweaks gnome-shell gnome-shell-extensions gnome-extensions-app gnome-shell-extension-appindicator gnome-browser-connector"
        fi
        ;;
      "fedora")
        ensure_packages "gtk-murrine-engine gtk2-engines"
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
          ensure_packages "gnome-tweaks gnome-shell gnome-shell-extensions gnome-extensions-app gnome-shell-extension-appindicator gnome-browser-connector"
        fi
        ;;
      "mac")
        error "Icon packs is not supported on your system."
        ;;
      esac

      if command -v gnome-extensions >/dev/null 2>&1; then
        while ! gnome-extensions list | grep -q "user-theme@gnome-shell-extensions.gcampax.github.com"; do
          echo "Please install https://extensions.gnome.org/extension/19/user-themes/"
          read -p "Press Enter after installing the extension..."
        done
        gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
      fi

      info "Downloading and applying icon pack..."
      wget -cO "/tmp/icon.zip" "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.zip"
      mkdir -P "/home/$USER/.icons"
      unzip -o "/tmp/icon.zip" -d "/tmp/"
      mv "/tmp/papirus-icon-theme-master/Papirus" "/home/$USER/.icons/Papirus"
      rm -rfv "/tmp/icon.zip" "/tmp/papirus-icon-theme-master"
      if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface icon-theme "Papirus"
      fi
      if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kwinrc "Icons" "Papirus"
      fi

      info "Downloading and applying GTK theme..."
      wget -cO "/tmp/theme.zip" "https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/master.zip"
      unzip -o "/tmp/theme.zip" -d "/tmp/"
      chmod +x "/tmp/WhiteSur-gtk-theme-master/install.sh"
      /tmp/WhiteSur-gtk-theme-master/install.sh --libadwaita
      rm -rfv "/tmp/theme.zip" "/tmp/WhiteSur-gtk-theme-master"
      if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.wm.preferences theme "WhiteSur-Dark"
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark"
        gsettings set org.gnome.shell.extensions.user-theme name "WhiteSur-Dark"
      fi
      if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kwinrc "Theme" "WhiteSur-Dark"
      fi

      info "Downloading and applying cursor theme..."
      wget -cO "/tmp/cursor.tar" "$(curl -s "https://api.github.com/repos/numixproject/numix-cursor-theme/releases/latest" | jq -r '.assets[] | select(.name | test(".*tar.*")) | .browser_download_url')"
      tar -xf "/tmp/cursor.tar" -C "/tmp"
      mv "/tmp/Numix-Cursor/" "/home/$USER/.icons/"
      rm -rfv "/tmp/cursor.tar"
      if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface cursor-theme "Numix-Cursor"
      fi
      if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kwinrc "CursorTheme" "Numix-Cursor"
      fi

      if command -v dconf >/dev/null 2>&1; then
        info "Configuring desktop environment settings..."
        dconf write /org/gnome/desktop/interface/enable-hot-corners true
        dconf write /org/gnome/desktop/interface/show-battery-percentage false
        dconf write /org/gnome/desktop/sound/allow-volume-above-100-percent true
        dconf write /org/gnome/desktop/wm/preferences/button-layout "'appmenu:minimize,maximize,close'"
        dconf write /org/gnome/mutter/workspaces-only-on-primary false
        dconf write /org/gnome/settings-daemon/plugins/power/power-button-action "'interactive'"
        if dconf list /org/gnome/shell/extensions/ | grep -q "dash-to-dock"; then
          dconf write /org/gnome/shell/extensions/dash-to-dock/always-center-icons true
          dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme true
          dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 40
          dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false
          dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
          dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false
          dconf write /org/gnome/shell/extensions/dash-to-dock/hotkeys-show-dock false
          dconf write /org/gnome/shell/extensions/dash-to-dock/multi-monitor true
          dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false
          dconf write /org/gnome/shell/extensions/dash-to-dock/show-show-apps-button true
          dconf write /org/gnome/shell/extensions/dash-to-dock/show-trash false
        fi

        info "Applying privacy settings..."
        dconf write /org/gnome/desktop/privacy/remember-recent-files false
        dconf write /org/gnome/desktop/privacy/remove-old-temp-files true
        dconf write /org/gnome/desktop/privacy/remove-old-trash-files true

        info "Applying custom shortcuts..."
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Control><Alt>t'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'gnome-terminal'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'gnome-terminal'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/binding "'<Super>e'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/command "'nautilus'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/name "'nautilus'"
        dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
      fi
      ;;
    "Extension")
      if ! command -v gnome-extensions >/dev/null 2>&1; then
        error "Extensions are only supported on GNOME desktop environment."
      fi
      if ! command -v pip3 >/dev/null 2>&1; then
        error "Please install python3-pip to manage GNOME extensions."
      fi

      info "Disabling unwanted GNOME extensions..."
      for EXTENSION in "tiling-assistant@ubuntu.com" "ding@rastersoft.com" "apps-menu@gnome-shell-extensions.gcampax.github.com" "places-menu@gnome-shell-extensions.gcampax.github.com" "launch-new-instance@gnome-shell-extensions.gcampax.github.com" "window-list@gnome-shell-extensions.gcampax.github.com" "auto-move-windows@gnome-shell-extensions.gcampax.github.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "light-style@gnome-shell-extensions.gcampax.github.com" "native-window-placement@gnome-shell-extensions.gcampax.github.com" "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com" "system-monitor@gnome-shell-extensions.gcampax.github.com" "windowsNavigator@gnome-shell-extensions.gcampax.github.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com"; do
        if gnome-extensions list | grep -q "$EXTENSION"; then
          gnome-extensions disable "$EXTENSION"
        fi
      done

      info "Installing extension installer..."
      export PATH="$HOME/.local/bin:$PATH"
      if ! command -v gext >/dev/null 2>&1; then
        pip3 install --break-system-packages gnome-extensions-cli
      fi

      info "Installing recommended extensions..."
      for EXTENSION in "AlphabeticalAppGrid@stuarthayhurst" "open-desktop-location@laura.media" "PersianCalendar@oxygenws.com" "Vitals@CoreCoding.com"; do
        if ! gnome-extensions list | grep -q "$EXTENSION"; then
          gext install "$EXTENSION"
        fi
      done

      info "Set vitals preset..."
      if ! dconf list /org/gnome/shell/extensions/ | grep -q "vitals"; then
        dconf write /org/gnome/shell/extensions/vitals/update-time 1
        dconf write /org/gnome/shell/extensions/vitals/position-in-panel 0
        dconf write /org/gnome/shell/extensions/vitals/hide-icons true
        dconf write /org/gnome/shell/extensions/vitals/hot-sensors "['__network-rx_max__', '_processor_frequency_', '_memory_allocated_', '__temperature_avg__']"
      fi
      ;;
    esac
    menu
  done
}

main "$@"
