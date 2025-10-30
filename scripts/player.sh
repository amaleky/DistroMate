#!/bin/bash

main() {
  PLAYER_OPTIONS=(
    "Video Player" "Spotify"
  )
  select PLAYER_CHOICE in "${PLAYER_OPTIONS[@]}"; do
    echo "Installing $PLAYER_CHOICE..."
    case $PLAYER_CHOICE in
      "Video Player")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id CodecGuide.K-LiteCodecPack.Full
        else
          case "$DETECTED_DISTRO" in
          "mac")
            ensure_packages "iina" "--cask"
            ;;
          *)
            ensure_packages "mpv"
            ;;
          esac
        fi
        ;;
      "Spotify")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install WhatsApp
        else
          case $DETECTED_DISTRO in
            "debian" | "fedora")
              sudo snap install spotify
              ;;
            "arch")
              ensure_packages "spotify-launcher"
              ;;
            "mac")
              brew install --cask spotify
              ;;
          esac
        fi
        ;;
    esac
    menu
  done
}

main "$@"
