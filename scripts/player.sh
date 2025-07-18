#!/bin/bash



main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id CodecGuide.K-LiteCodecPack.Full
  else
    case $DETECTED_DISTRO in
    "debian")
      sudo apt install -y mpv
      ;;
    "arch")
      yay -S --noconfirm --needed --removemake --cleanafter mpv
      ;;
    "fedora")
      sudo dnf install -y mpv
      ;;
    "mac")
      brew install --cask iina
      ;;
    esac
  fi
}

main "$@"
