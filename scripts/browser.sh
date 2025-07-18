#!/bin/bash

main() {
  BROWSER_OPTIONS=(
    "Chrome" "Firefox" "Edge" "Brave"
  )

  select BROWSER_CHOICE in "${BROWSER_OPTIONS[@]}"; do
    echo "Installing $BROWSER_CHOICE..."
    case $BROWSER_CHOICE in
    "Chrome")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id Google.Chrome
      else
        case $DETECTED_DISTRO in
        "debian")
          wget -cO /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
          sudo apt install -y /tmp/google-chrome.deb
          rm -rfv /tmp/google-chrome.deb
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter google-chrome
          ;;
        "fedora")
          sudo dnf install -y google-chrome
          ;;
        "mac")
          brew install --cask google-chrome
          ;;
        esac
      fi
      ;;
    "Firefox")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id Mozilla.Firefox
      else
        case $DETECTED_DISTRO in
        "debian")
          wget -cO- "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" | sudo tar -xj -C /opt
          sudo ln -vs /opt/firefox/firefox /usr/bin/firefox
          sudo wget -cO /usr/share/applications/firefox.desktop "https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop"
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter firefox
          ;;
        "fedora")
          sudo dnf install -y firefox
          ;;
        "mac")
          brew install --cask firefox
          ;;
        esac
      fi
      ;;
    "Edge")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id Microsoft.Edge
      else
        case $DETECTED_DISTRO in
        "debian")
          BASE_URL="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/"
          LATEST_DEB=$(wget -O- "$BASE_URL" | grep -oP '(?<=href=")[^/]*?_amd64\.deb' | sort -V | tail -n1)
          wget -cO /tmp/edge.deb "${BASE_URL}${LATEST_DEB}"
          sudo apt install -y /tmp/edge.deb
          rm -rfv /tmp/edge.deb
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter microsoft-edge-stable-bin
          ;;
        "fedora")
          BASE_URL="https://packages.microsoft.com/yumrepos/edge/Packages/m/"
          LATEST_RPM=$(wget -O- "$BASE_URL" | grep -oP '(?<=href=")[^/]*?\.x86_64\.rpm' | sort -V | tail -n1)
          wget -cO /tmp/edge.rpm "${BASE_URL}${LATEST_RPM}"
          sudo dnf install -y /tmp/edge.rpm
          rm -rfv /tmp/edge.rpm
          ;;
        "mac")
          brew install --cask microsoft-edge
          ;;
        esac
      fi
      ;;
    "Brave")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id Brave.Brave
      else
        case $DETECTED_DISTRO in
        "debian" | "fedora")
          curl -fsS https://dl.brave.com/install.sh | sh
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter brave-bin
          ;;
        "mac")
          brew install --cask brave-browser
          ;;
        esac
      fi
      ;;
    esac
    menu
  done
}

main "$@"
