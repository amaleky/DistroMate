#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
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
}

main "$@"
