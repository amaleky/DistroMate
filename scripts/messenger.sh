#!/bin/bash

main() {
  MESSENGER_OPTIONS=(
    "Telegram" "WhatsApp" "Teams" "Slack" "Discord" "Zoom"
  )
  select BROWSER_CHOICE in "${MESSENGER_OPTIONS[@]}"; do
    echo "Installing $BROWSER_CHOICE..."
    case $BROWSER_CHOICE in
      "Telegram")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Telegram.TelegramDesktop
        else
          case $DETECTED_DISTRO in
            "debian" | "fedora")
              sudo snap install telegram-desktop
              ;;
            "arch")
              ensure_packages "telegram-desktop"
              ;;
            "mac")
              brew install --cask telegram
              ;;
          esac
        fi
        ;;
      "WhatsApp")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id WhatsApp.WhatsApp
        else
          case $DETECTED_DISTRO in
            "debian" | "fedora")
              sudo snap install whatsapp-linux-desktop
              ;;
            "arch")
              ensure_packages "whatsapp-linux-desktop"
              ;;
            "mac")
              brew install --cask whatsapp
              ;;
          esac
        fi
        ;;
      "Teams")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Microsoft.Teams
        else
          case $DETECTED_DISTRO in
            "debian" | "fedora")
              sudo snap install teams-for-linux
              ;;
            "arch")
              ensure_packages "teams-for-linux"
              ;;
            "mac")
              brew install --cask microsoft-teams
              ;;
          esac
        fi
        ;;
      "Slack")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id SlackTechnologies.Slack
        else
          case $DETECTED_DISTRO in
            "debian" | "fedora")
              sudo snap install slack
              ;;
            "arch")
              ensure_packages "slack-desktop"
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
            "debian" | "fedora")
              sudo snap install discord
              ;;
            "arch")
              ensure_packages "discord"
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
            "debian" | "fedora")
              sudo snap install zoom-client
              ;;
            "arch")
              ensure_packages "zoom"
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
