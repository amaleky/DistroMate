#!/bin/bash

main() {
  PLAYER_OPTIONS=(
    "V2rayN" "Sing-Box" "FortiVpn" "Wireguard" "OpenVpn" "Scanner"
  )
  select PLAYER_CHOICE in "${PLAYER_OPTIONS[@]}"; do
    echo "Installing $PLAYER_CHOICE..."
    case $PLAYER_CHOICE in
      "V2rayN")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id 2dust.v2rayN
          v2rayN.exe
        else
          case "$DETECTED_DISTRO" in
          "debian")
            wget -cO "/tmp/v2rayN.deb" "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-linux-64.deb"
            ensure_packages "/tmp/v2rayN.deb"
            rm -rfv "/tmp/v2rayN.deb"
            ;;
          "fedora")
            wget -cO "/tmp/v2rayN.rpm" "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-linux-rhel-64.rpm"
            ensure_packages "/tmp/v2rayN.rpm"
            rm -rfv "/tmp/v2rayN.rpm"
            ;;
          "mac")
            wget -cO "/Applications/v2rayN.dmg" "https://github.com/2dust/v2rayN/releases/download/7.16.6/v2rayN-macos-64.dmg"
            ;;
          *)
            wget -cO "/tmp/v2rayN.zip" "https://github.com/2dust/v2rayN/releases/download/7.22.7/v2rayN-linux-64.zip"
            unzip -o "/tmp/v2rayN.zip" -d "/tmp/"
            rm -rfv "/tmp/v2rayN.zip"
            sudo mv "/tmp/v2rayN-linux-64/" "/opt/v2rayn"
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
            curl -L -o /tmp/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-${REMOTE_VERSION}-linux-amd64.tar.gz" || error "Failed to download sing-box."
            tar -xvzf /tmp/sing-box.tar.gz -C /tmp
            sudo mv /tmp/sing-box-*/sing-box /usr/bin/sing-box
            chmod +x /usr/bin/sing-box
            rm -rfv /tmp/sing-box-* /tmp/sing-box.tar.gz
            ;;
        esac
        ;;
      "FortiVpn")
        if [ "$IS_WSL" == "true" ]; then
          winget.exe install -e --id Fortinet.FortiClientVPN
        else
          ensure_packages "openfortivpn"
        fi
        ;;
      "Wireguard")
        if [ "$IS_WSL" == "true" ]; then
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
        if [ "$IS_WSL" == "true" ]; then
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
        wget -qO- https://raw.githubusercontent.com/amaleky/WrtMate/main/scripts/packages/scanner.sh | bash
        ;;
    esac
    menu
  done
}

main "$@"
