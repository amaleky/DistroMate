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
            "debian")
              sudo snap install telegram-desktop
              ;;
            "arch")
              ensure_packages "telegram-desktop"
              ;;
            "fedora")
              flatpak install -y flathub org.telegram.desktop
              ;;
            "mac")
              brew install --cask telegram
              ;;
          esac
        fi
        ;;
      "WhatsApp")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install WhatsApp
        else
          case $DETECTED_DISTRO in
            "debian")
              sudo snap install whatsapp-linux-desktop
              ;;
            "arch")
              ensure_packages "whatsapp-linux-desktop"
              ;;
            "fedora")
              flatpak install -y flathub com.ktechpit.whatsie
              ;;
            "mac")
              brew install --cask whatsapp
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
              sudo snap install slack
              ;;
            "arch")
              ensure_packages "slack-desktop"
              ;;
            "fedora")
              flatpak install -y flathub com.slack.Slack
              ;;
            "mac")
              brew install --cask slack
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
              sudo snap install discord
              ;;
            "arch")
              ensure_packages "discord"
              ;;
            "fedora")
              flatpak install -y flathub com.discordapp.Discord
              ;;
            "mac")
              brew install --cask discord
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
              sudo snap install zoom-client
              ;;
            "arch")
              ensure_packages "zoom"
              ;;
            "fedora")
              flatpak install -y flathub us.zoom.Zoom
              ;;
            "mac")
              brew install --cask zoom
              ;;
          esac
        fi
        ;;
    esac
    menu
  done
}

main "$@"
