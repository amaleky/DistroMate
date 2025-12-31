#!/bin/bash

main() {
  PLAYER_OPTIONS=(
    "Video Player" "Spotify" "Jellyfin"
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
            ensure_packages "vlc vlc-plugins-all ffmpeg gstreamer-plugins-bad gstreamer-plugins-ugly"
            ;;
          "fedora")
            ensure_packages "vlc ffmpeg ffmpeg-free gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras gstreamer1-plugins-good gstreamer1-plugins-base gstreamer1-plugins-ugly gstreamer1-plugins-ugly-free gstreamer1-plugins-bad-freeworld gstreamer1-libav gstreamer1-plugin-openh264" "--allowerasing"
            ;;
          "mac")
            ensure_packages "iina" "--cask"
            ;;
          esac
        fi
        ;;
      "Spotify")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Spotify.Spotify
        else
          case $DETECTED_DISTRO in
            "debian")
              curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
              echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
              sudo apt update
              ensure_packages "spotify-client"
              ;;
            "mac")
              ensure_packages "spotify" "--cask"
              ;;
            *)
              APP_NAME="spotify"
              DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
              sudo rm -rfv "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
              cat << EOF > "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
[Desktop Entry]
Name=Spotify
Comment=Spotify Web
Exec=google-chrome-stable --no-sandbox --profile-directory="Default" --app=https://open.spotify.com
Icon=spotify
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
      "Jellyfin")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Jellyfin.JellyfinMediaPlayer
        else
          case $DETECTED_DISTRO in
            "debian")
              ensure_packages "jq"
              REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/jellyfin/jellyfin-media-player/releases/latest" | jq -r '.tag_name')"
              wget -cO "/tmp/jellyfin.deb" "https://github.com/jellyfin/jellyfin-media-player/releases/download/v$REMOTE_VERSION/jellyfin-media-player_$REMOTE_VERSION-1_amd64-$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2).deb"
              ensure_packages "/tmp/jellyfin.deb"
              rm -rfv "/tmp/jellyfin.deb"
              ;;
            "arch")
              ensure_packages "jellyfin-desktop"
              ;;
            "fedora")
              sudo dnf copr enable sammyette/jellyfin-media-player
              ensure_packages "jellyfin-media-player"
              ;;
            "mac")
              ensure_packages "jellyfin-media-player" "--cask"
              ;;
          esac
        fi
        ;;
    esac
    menu
  done
}

main "$@"
