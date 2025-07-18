#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id OBSProject.OBSStudio
  else
    case "$DETECTED_DISTRO" in
    "mac")
      ensure_packages "obs" "--cask"
      ;;
    *)
      ensure_packages "obs-studio"
      ;;
    esac
  fi
}

main "$@"
