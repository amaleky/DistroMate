#!/bin/sh

main() {
  while :; do
    printf '%s\n' '1) V2rayN'
    printf '%s\n' '2) Sing-Box'
    printf '%s\n' '3) FortiVpn'
    printf '%s\n' '4) Wireguard'
    printf '%s\n' '5) OpenVpn'
    printf '%s\n' '6) Scanner'
    printf '%s' 'Enter your choice: '
    IFS= read -r PLAYER_CHOICE_INDEX || return 0
    case "$PLAYER_CHOICE_INDEX" in
      1) PLAYER_CHOICE="V2rayN" ;;
      2) PLAYER_CHOICE="Sing-Box" ;;
      3) PLAYER_CHOICE="FortiVpn" ;;
      4) PLAYER_CHOICE="Wireguard" ;;
      5) PLAYER_CHOICE="OpenVpn" ;;
      6) PLAYER_CHOICE="Scanner" ;;
      *) printf '%s\n' "Invalid option $PLAYER_CHOICE_INDEX" >&2; continue ;;
    esac
    echo "Installing $PLAYER_CHOICE..."
    case $PLAYER_CHOICE in
      "V2rayN")
        if [ "$SYSTEM_ARCH" = "arm64" ]; then
          V2RAYN_ARCH="arm64"
        else
          V2RAYN_ARCH="64"
        fi
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id 2dust.v2rayN
          v2rayN.exe
        else
          case "$DETECTED_DISTRO" in
          "debian")
            curl -fL "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-linux-$V2RAYN_ARCH.deb" -o "/tmp/v2rayN.deb"
            ensure_packages "/tmp/v2rayN.deb"
            rm -rfv "/tmp/v2rayN.deb"
            ;;
          "fedora")
            curl -fL "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-linux-rhel-$V2RAYN_ARCH.rpm" -o "/tmp/v2rayN.rpm"
            ensure_packages "/tmp/v2rayN.rpm"
            rm -rfv "/tmp/v2rayN.rpm"
            ;;
          "mac")
            curl -fL "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-macos-$V2RAYN_ARCH.dmg" -o "/Applications/v2rayN.dmg"
            ;;
          *)
            curl -fL "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-linux-$V2RAYN_ARCH.zip" -o "/tmp/v2rayN.zip"
            unzip -o "/tmp/v2rayN.zip" -d "/tmp/"
            rm -rfv "/tmp/v2rayN.zip"
            sudo mv "/tmp/v2rayN-linux-$V2RAYN_ARCH/" "/opt/v2rayn"
            chmod +x "/opt/v2rayn/v2rayN"
            APP_NAME="v2rayN"
            EXECUTABLE_PATH="/opt/v2rayn/v2rayN"
            RAW_ICON="/opt/v2rayn/v2rayN.png"
            DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
            sudo rm -rfv "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
            cat << EOF > "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
[Desktop Entry]
Name=$APP_NAME
Comment=GUI client for V2Ray
Exec=$EXECUTABLE_PATH --no-sandbox
Icon=$RAW_ICON
Type=Application
Terminal=false
Categories=Internet;
StartupNotify=true
EOF
            chmod +x "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
            update-desktop-database "$DESKTOP_ENTRY_DIR"
            ;;
          esac
        fi
        ;;
      "Sing-Box")
        case $DETECTED_DISTRO in
          "mac")
            ensure_packages "sing-box"
            ;;
          *)
            ensure_packages "jq"
            REMOTE_VERSION="$(curl -s -L "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r '.tag_name | ltrimstr("v")')"
            curl -L -o /tmp/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-${REMOTE_VERSION}-linux-$SYSTEM_ARCH.tar.gz" || error "Failed to download sing-box."
            tar -xvzf /tmp/sing-box.tar.gz -C /tmp
            sudo mv /tmp/sing-box-*/sing-box /usr/bin/sing-box
            chmod +x /usr/bin/sing-box
            rm -rfv /tmp/sing-box-* /tmp/sing-box.tar.gz
            ;;
        esac
        ;;
      "FortiVpn")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Fortinet.FortiClientVPN
        else
          ensure_packages "openfortivpn"
        fi
        ;;
      "Wireguard")
        if [ "$IS_WSL" = "true" ]; then
          winget.exe install -e --id Fortinet.FortiClientVPN
        else
          case "$DETECTED_DISTRO" in
          "mac")
            ensure_packages "wireguard-tools"
            ;;
          "debian")
            ensure_packages "wireguard-tools"
            if command -v gnome-shell >/dev/null 2>&1; then
              ensure_packages "network-manager-wireguard"
            fi
            ;;
          "arch")
            ensure_packages "wireguard-tools"
            if command -v gnome-shell >/dev/null 2>&1; then
              ensure_packages "networkmanager-wireguard"
            fi
            ;;
          "fedora")
            ensure_packages "wireguard-tools"
            if command -v gnome-shell >/dev/null 2>&1; then
              ensure_packages "NetworkManager-wireguard"
            fi
            ;;
          esac
        fi
        ;;
      "OpenVpn")
        if [ "$IS_WSL" = "true" ]; then
          winget install -e --id OpenVPNTechnologies.OpenVPNConnect
        else
          case "$DETECTED_DISTRO" in
          "mac")
            ensure_packages "openvpn-connect" "--cask"
            ;;
          *)
            ensure_packages "openvpn"
            if command -v gnome-shell >/dev/null 2>&1; then
              ensure_packages "network-manager-openvpn-gnome"
            fi
            ;;
          esac
        fi
        ;;
      "Scanner")
        curl -fsSL https://raw.githubusercontent.com/amaleky/WrtMate/main/scripts/packages/scanner.sh | sh
        ;;
    esac
    menu
  done
}

main "$@"
