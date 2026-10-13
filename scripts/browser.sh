#!/bin/sh

main() {
  while :; do
    printf '%s\n' '1) Chrome'
    printf '%s\n' '2) Firefox'
    printf '%s\n' '3) Edge'
    printf '%s\n' '4) Brave'
    printf '%s' 'Enter your choice: '
    IFS= read -r BROWSER_CHOICE_INDEX || return 0
    case "$BROWSER_CHOICE_INDEX" in
      1) BROWSER_CHOICE="Chrome" ;;
      2) BROWSER_CHOICE="Firefox" ;;
      3) BROWSER_CHOICE="Edge" ;;
      4) BROWSER_CHOICE="Brave" ;;
      *) printf '%s\n' "Invalid option $BROWSER_CHOICE_INDEX" >&2; continue ;;
    esac
    info "Installing $BROWSER_CHOICE..."
    case "$BROWSER_CHOICE" in
    "Chrome")
      if [ "$IS_WSL" = "true" ]; then
        if [ "$SYSTEM_ARCH" = "arm64" ]; then
          winget.exe install -e --id Google.Chrome --architecture arm64
        else
          winget.exe install -e --id Google.Chrome
        fi
      else
        case "$DETECTED_DISTRO" in
        "debian")
          curl -fL "https://dl.google.com/linux/direct/google-chrome-stable_current_${DEB_ARCH}.deb" -o "/tmp/google-chrome.deb"
          ensure_packages "/tmp/google-chrome.deb"
          rm -rfv "/tmp/google-chrome.deb"
          ;;
        "mac")
          ensure_packages "google-chrome" "--cask"
          ;;
        "fedora")
          ensure_packages "google-chrome-stable"
          ;;
        *)
          ensure_packages "google-chrome"
          ;;
        esac
      fi
      ;;
    "Firefox")
      if [ "$IS_WSL" = "true" ]; then
        winget.exe install -e --id Mozilla.Firefox
      else
        case "$DETECTED_DISTRO" in
        "debian")
          if [ "$SYSTEM_ARCH" = "arm64" ]; then
            FIREFOX_OS="linux64-aarch64"
          else
            FIREFOX_OS="linux64"
          fi
          curl -fsSL "https://download.mozilla.org/?product=firefox-latest&os=$FIREFOX_OS&lang=en-US" | sudo tar -xJ -C /opt
          sudo ln -vs /opt/firefox/firefox /usr/bin/firefox
          sudo curl -fL -o /usr/share/applications/firefox.desktop "https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop"
          ;;
        "mac")
          ensure_packages "firefox" "--cask"
          ;;
        *)
          ensure_packages "firefox"
          ;;
        esac
      fi
      ;;
    "Edge")
      if [ "$IS_WSL" = "true" ]; then
        if [ "$SYSTEM_ARCH" = "arm64" ]; then
          winget.exe install -e --id Microsoft.Edge --architecture arm64
        else
          winget.exe install -e --id Microsoft.Edge
        fi
      else
        case "$DETECTED_DISTRO" in
        "debian")
          BASE_URL="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/"
          LATEST_DEB=$(curl -fsSL "$BASE_URL" | grep -oP "(?<=href=\")[^/]*?_${DEB_ARCH}\.deb" | sort -V | tail -n1)
          curl -fL -o "/tmp/edge.deb" "${BASE_URL}${LATEST_DEB}"
          ensure_packages "/tmp/edge.deb"
          rm -rfv "/tmp/edge.deb"
          ;;
        "arch")
          ensure_packages "microsoft-edge-stable-bin"
          ;;
        "fedora")
          BASE_URL="https://packages.microsoft.com/yumrepos/edge/Packages/m/"
          LATEST_RPM=$(curl -fsSL "$BASE_URL" | grep -oP "(?<=href=\")[^/]*?\.${RPM_ARCH}\.rpm" | sort -V | tail -n1)
          curl -fL -o "/tmp/edge.rpm" "${BASE_URL}${LATEST_RPM}"
          ensure_packages "/tmp/edge.rpm"
          rm -rfv "/tmp/edge.rpm"
          ;;
        "mac")
          ensure_packages "microsoft-edge" "--cask"
          ;;
        esac
      fi
      ;;
    "Brave")
      if [ "$IS_WSL" = "true" ]; then
        winget.exe install -e --id Brave.Brave
      else
        case "$DETECTED_DISTRO" in
        "debian" | "fedora")
          curl -fsS https://dl.brave.com/install.sh | sh
          ;;
        "arch")
          ensure_packages "brave-bin"
          ;;
        "mac")
          ensure_packages "brave-browser" "--cask"
          ;;
        esac
      fi
      ;;
    esac
    menu
  done
}

main "$@"
