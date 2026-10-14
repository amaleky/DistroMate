#!/bin/sh

main() {
  while :; do
    printf '%s\n' '1) Telegram'
    printf '%s\n' '2) WhatsApp'
    printf '%s\n' '3) Slack'
    printf '%s\n' '4) Discord'
    printf '%s\n' '5) Zoom'
    printf '%s' 'Enter your choice: '
    IFS= read -r BROWSER_CHOICE_INDEX || return 0
    case "$BROWSER_CHOICE_INDEX" in
      1) BROWSER_CHOICE="Telegram" ;;
      2) BROWSER_CHOICE="WhatsApp" ;;
      3) BROWSER_CHOICE="Slack" ;;
      4) BROWSER_CHOICE="Discord" ;;
      5) BROWSER_CHOICE="Zoom" ;;
      *) printf '%s\n' "Invalid option $BROWSER_CHOICE_INDEX" >&2; continue ;;
    esac
    echo "Installing $BROWSER_CHOICE..."
    case $BROWSER_CHOICE in
      "Telegram")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Telegram.TelegramDesktop
        else
          case $DETECTED_DISTRO in
            "arch")
              ensure_packages "telegram-desktop"
              ;;
            "mac")
              ensure_packages "telegram" "--cask"
              ;;
            *)
              curl -fsSL "https://telegram.org/dl/desktop/linux" | sudo tar -xJ -C /opt
              /opt/Telegram/Telegram &
              ;;
          esac
        fi
        ;;
      "WhatsApp")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install WhatsApp
        else
          case $DETECTED_DISTRO in
            "mac")
              ensure_packages "whatsapp" "--cask"
              ;;
            *)
              APP_NAME="whatsapp"
              RAW_ICON="/usr/share/icons/hicolor/scalable/whatsapp.svg"
              sudo rm -rfv $RAW_ICON
              sudo curl -fL "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/whatsapp.svg" -o "$RAW_ICON"
              DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
              sudo rm -rfv "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
              cat << EOF > "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
[Desktop Entry]
Name=WhatsApp
Comment=WhatsApp Web
Exec=google-chrome-stable --no-sandbox --profile-directory="Default" --app=https://web.whatsapp.com
Icon=$RAW_ICON
Type=Application
Terminal=false
Categories=Internet;
StartupNotify=true
EOF
              update-desktop-database "$DESKTOP_ENTRY_DIR"
              ;;
          esac
        fi
        ;;
      "Slack")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id SlackTechnologies.Slack
        else
          case $DETECTED_DISTRO in
            "debian")
              url="https://slack.com/downloads/instructions/linux?ddl=1&build=deb&nojsmode=1"
              curl -fL -o "/tmp/slack.deb" "$(curl -s -L "$url" | grep -oP 'href="\K(https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[^"]+\.deb)' | head -n 1)"
              ensure_packages "/tmp/slack.deb"
              rm -rfv "/tmp/slack.deb"
              ;;
            "arch")
              ensure_packages "slack-desktop"
              ;;
            "fedora")
              url="https://slack.com/downloads/instructions/linux?ddl=1&build=rpm&nojsmode=1"
              curl -fL -o "/tmp/slack.rpm" "$(curl -s -L "$url" | grep -oP 'href="\K(https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[^"]+\.rpm)' | head -n 1)"
              ensure_packages "/tmp/slack.rpm"
              rm -rfv "/tmp/slack.rpm"
              ;;
            "mac")
              ensure_packages "slack" "--cask"
              ;;
          esac
        fi
        ;;
      "Discord")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Discord.Discord
        else
          case $DETECTED_DISTRO in
            "debian")
              curl -fL "https://discord.com/api/download?platform=linux" -o "/tmp/discord.deb"
              ensure_packages "/tmp/discord.deb"
              rm -rfv "/tmp/discord.deb"
              ;;
            "arch")
              ensure_packages "discord"
              ;;
            "fedora")
              ensure_packages "discord"
              ;;
            "mac")
              ensure_packages "discord" "--cask"
              ;;
          esac
        fi
        ;;
      "Zoom")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Zoom.Zoom
        else
          case $DETECTED_DISTRO in
            "debian")
              ensure_packages "jq"
              ZOOM_VERSION="$(curl -fsSL "https://zoom.us/rest/download?os=linux" | jq -r '.result.downloadVO.zoom.version')"
              curl -fL "https://cdn.zoom.us/prod/$ZOOM_VERSION/zoom_amd64.deb" -o "/tmp/zoom.deb"
              ensure_packages "/tmp/zoom.deb"
              rm -rfv "/tmp/zoom.deb"
              ;;
            "arch")
              ensure_packages "zoom"
              ;;
            "fedora")
              ensure_packages "jq"
              ZOOM_VERSION="$(curl -fsSL "https://zoom.us/rest/download?os=linux" | jq -r '.result.downloadVO.zoom.version')"
              curl -fL "https://cdn.zoom.us/prod/$ZOOM_VERSION/zoom_x86_64.rpm" -o "/tmp/zoom.rpm"
              ensure_packages "/tmp/zoom.rpm"
              rm -rfv "/tmp/zoom.rpm"
              ;;
            "mac")
              ensure_packages "zoom" "--cask"
              ;;
          esac
        fi
        ;;
    esac
    menu
  done
}

main "$@"
