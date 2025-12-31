#!/bin/bash

main() {
  MESSENGER_OPTIONS=(
    "Telegram" "WhatsApp" "Slack" "Discord" "Zoom"
  )
  select BROWSER_CHOICE in "${MESSENGER_OPTIONS[@]}"; do
    echo "Installing $BROWSER_CHOICE..."
    case $BROWSER_CHOICE in
      "Telegram")
        if [ "$IS_WSL" == "true" ]; then
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
              wget -cO- "https://telegram.org/dl/desktop/linux" | sudo tar -xJ -C /opt
              /opt/Telegram/Telegram &
              ;;
          esac
        fi
        ;;
      "WhatsApp")
        if [ "$IS_WSL" == "true" ]; then
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
              sudo wget -cO "$RAW_ICON" "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/whatsapp.svg"
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
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id SlackTechnologies.Slack
        else
          case $DETECTED_DISTRO in
            "debian")
              url="https://slack.com/downloads/instructions/linux?ddl=1&build=deb&nojsmode=1"
              wget -cO "/tmp/slack.deb" "$(curl -s -L "$url" | grep -oP 'href="\K(https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[^"]+\.deb)' | head -n 1)"
              ensure_packages "/tmp/slack.deb"
              rm -rfv "/tmp/slack.deb"
              ;;
            "arch")
              ensure_packages "slack-desktop"
              ;;
            "fedora")
              url="https://slack.com/downloads/instructions/linux?ddl=1&build=deb&nojsmode=1"
              wget -cO "/tmp/slack.rpm" "$(curl -s -L "$url" | grep -oP 'href="\K(https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[^"]+\.rpm)' | head -n 1)"
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
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Discord.Discord
        else
          case $DETECTED_DISTRO in
            "debian")
              wget -cO "/tmp/discord.deb" "https://discord.com/api/download?platform=linux"
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
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Zoom.Zoom
        else
          case $DETECTED_DISTRO in
            "debian")
              ensure_packages "jq"
              wget -cO "/tmp/zoom.deb" "https://cdn.zoom.us/prod/$(curl -s -L "https://zoom.us/rest/download?os=linux" | jq -r '.result.downloadVO.zoom.version')/zoom_amd64.deb"
              ensure_packages "/tmp/zoom.deb"
              rm -rfv "/tmp/zoom.deb"
              ;;
            "arch")
              ensure_packages "zoom"
              ;;
            "fedora")
              ensure_packages "jq"
              wget -cO "/tmp/zoom.rpm" "https://cdn.zoom.us/prod/$(curl -s -L "https://zoom.us/rest/download?os=linux" | jq -r '.result.downloadVO.zoom.version')/zoom_x86_64.rpm"
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
