#!/bin/sh

main() {
  while :; do
    printf '%s\n' '1) Video Player'
    printf '%s\n' '2) Spotify'
    printf '%s\n' '3) Jellyfin'
    printf '%s' 'Enter your choice: '
    IFS= read -r PLAYER_CHOICE_INDEX || return 0
    case "$PLAYER_CHOICE_INDEX" in
      1) PLAYER_CHOICE="Video Player" ;;
      2) PLAYER_CHOICE="Spotify" ;;
      3) PLAYER_CHOICE="Jellyfin" ;;
      *) printf '%s\n' "Invalid option $PLAYER_CHOICE_INDEX" >&2; continue ;;
    esac
    echo "Installing $PLAYER_CHOICE..."
    case $PLAYER_CHOICE in
      "Video Player")
        if [ "$IS_WSL" = "true" ]; then
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
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Spotify.Spotify
        else
          case $DETECTED_DISTRO in
            "debian")
              curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
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
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Jellyfin.JellyfinMediaPlayer
        else
          case $DETECTED_DISTRO in
            "debian")
              ensure_packages "jq"
              REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/jellyfin/jellyfin-desktop/releases/latest" | jq -r '.tag_name | ltrimstr("v")')"
              DEBIAN_CODENAME="$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)"
              curl -fL "https://github.com/jellyfin/jellyfin-desktop/releases/download/v$REMOTE_VERSION/jellyfin-media-player_$REMOTE_VERSION-$DEBIAN_CODENAME.deb" -o "/tmp/jellyfin.deb"
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
