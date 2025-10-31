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
          "debian")
            ensure_packages "vlc ffmpeg ubuntu-restricted-extras libavcodec-extra"
            ;;
          "arch")
            ensure_packages "vlc ffmpeg gstreamer-plugins-bad gstreamer-plugins-ugly"
            ;;
          "fedora")
            ensure_packages "vlc ffmpeg gstreamer1-plugins-{bad-free,bad-free-extras,good,base,ugly,ugly-free,bad-freeworld} gstreamer1-libav gstreamer1-plugin-openh264" "--allowerasing"
            ;;
          "mac")
            ensure_packages "iina" "--cask"
            ;;
          esac
        fi
        ;;
      "Spotify")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install WhatsApp
        else
          case $DETECTED_DISTRO in
            "debian")
              sudo snap install spotify
              ;;
            "arch")
              ensure_packages "spotify-launcher"
              ;;
            "fedora")
              flatpak install -y flathub com.spotify.Client
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
