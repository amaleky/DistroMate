#!/bin/sh

# DistroMate Installation Script
# Usage: sh -c "$(curl -fsSL https://raw.githubusercontent.com/amaleky/DistroMate/main/install.sh)"

REPO_URL="https://raw.githubusercontent.com/amaleky/DistroMate/main"
export REPO_URL

run_remote_script() {
  script_name=$1
  script_file=$(mktemp "${TMPDIR:-/tmp}/distromate.XXXXXX") || exit 1
  if ! curl -fsSL "$REPO_URL/scripts/$script_name" -o "$script_file"; then
    rm -f "$script_file"
    printf '%s\n' "[ERROR] Unable to download $script_name" >&2
    return 1
  fi
  . "$script_file"
  status=$?
  rm -f "$script_file"
  return $status
}

run_menu() {
  while :; do
    printf '%s\n' \
      '1) Upgrade' '2) Bloatware' '3) Recommended' '4) Driver' \
      '5) Browser' '6) Development' '7) Player' '8) Messenger' \
      '9) Downloader' '10) VPN' '11) Virtualization' '12) RemoteDesktop' \
      '13) ScreenRecorder' '14) Services' '15) Configs' '16) Quit'
    printf '%s' 'Enter your choice [1-16]: '
    IFS= read -r choice || exit 0
    case "$choice" in
      1) run_remote_script upgrade.sh ;;
      2) run_remote_script bloatware.sh ;;
      3) run_remote_script recommended.sh ;;
      4) run_remote_script driver.sh ;;
      5) run_remote_script browser.sh ;;
      6) run_remote_script development.sh ;;
      7) run_remote_script player.sh ;;
      8) run_remote_script messenger.sh ;;
      9) run_remote_script downloader.sh ;;
      10) run_remote_script vpn.sh ;;
      11) run_remote_script virtualization.sh ;;
      12) run_remote_script remote-desktop.sh ;;
      13) run_remote_script screen-recorder.sh ;;
      14) run_remote_script services.sh ;;
      15) run_remote_script configs.sh ;;
      16) printf '%s\n' 'Exiting DistroMate installer. Thank you for using DistroMate!'; return 0 ;;
      *) printf '%s\n' "[WARNING] Invalid option $choice" >&2 ;;
    esac
    printf '\n'
  done
}

utils_file=$(mktemp "${TMPDIR:-/tmp}/distromate-utils.XXXXXX") || exit 1
trap 'rm -f "$utils_file"' EXIT HUP INT TERM
curl -fsSL "$REPO_URL/scripts/utils.sh" -o "$utils_file" || exit 1
. "$utils_file" || exit 1
run_menu "$@"
