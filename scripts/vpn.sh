#!/bin/bash

main() {
  PLAYER_OPTIONS=(
    "V2rayN" "Sing-Box" "FortiVpn" "Wireguard" "OpenVpn"
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
          "arch")
            ensure_packages "v2rayn-bin"
            ;;
          "fedora")
            wget -cO "/tmp/v2rayN.deb" "https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-linux-rhel-64.rpm"
            ensure_packages "/tmp/v2rayN.deb"
            rm -rfv "/tmp/v2rayN.deb"
            ;;
          "mac")
            wget -cO "/Applications/v2rayN.dmg" "https://github.com/2dust/v2rayN/releases/download/7.16.6/v2rayN-macos-64.dmg"
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
    esac
    menu
  done
}

main "$@"
