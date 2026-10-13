#!/bin/sh

# Colors for terminal output
readonly RED=$(printf '\033[1;31m')
readonly GREEN=$(printf '\033[1;32m')
readonly YELLOW=$(printf '\033[1;33m')
readonly BLUE=$(printf '\033[1;34m')
readonly NC=$(printf '\033[0m') # No Color

info() {
  printf '%s\n' "${BLUE}[INFO]${NC} $1"
}

warning() {
  printf '%s\n' "${YELLOW}[WARNING]${NC} $1" >&2
}

error() {
  printf '%s\n' "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

success() {
  printf '%s\n' "${GREEN}[SUCCESS]${NC} $1"
}

confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local options="[y/N]"
  [ "$default" = "y" ] && options="[Y/n]"

  printf "%s" "$prompt $options: "
  IFS= read -r response
  response="${response:-$default}"
  case "$response" in Y|y|Yes|yes) return 0 ;; *) return 1 ;; esac
}

ensure_packages() {
  local PACKAGES=$1
  local FLAGS=$2

  info "Installing $PACKAGES..."

  case "$DETECTED_DISTRO" in
    "debian")
      sudo apt install -y $FLAGS $PACKAGES
      ;;
    "arch")
      yes | yay -S --needed --removemake --cleanafter $FLAGS $PACKAGES
      ;;
    "fedora")
      sudo dnf install -y --skip-unavailable $FLAGS $PACKAGES
      ;;
    "mac")
      brew install --yes $FLAGS $PACKAGES
      ;;
  esac
}

remove_packages() {
  local PACKAGES="$1"
  for PACKAGE in $PACKAGES; do
    info "Removing $PACKAGE..."
    case "$DETECTED_DISTRO" in
    "debian")
      sudo apt purge -y --autoremove "$PACKAGE"
      ;;
    "arch")
      yay -Rcnssu --noconfirm "$PACKAGE"
      ;;
    "fedora")
      sudo dnf remove -y "$PACKAGE"
      ;;
    "mac")
      brew uninstall --zap --force "$PACKAGE"
      ;;
    esac
  done
}

detect_env() {
  DISTRO_ID=
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID=${ID:-}
    export DISTRO_ID
  fi

  case "$(uname -m)" in
  "x86_64" | "amd64")
    export SYSTEM_ARCH="amd64"
    export DEB_ARCH="amd64"
    export RPM_ARCH="x86_64"
    export URL_ARCH="x64"
    ;;
  "aarch64" | "arm64")
    export SYSTEM_ARCH="arm64"
    export DEB_ARCH="arm64"
    export RPM_ARCH="aarch64"
    export URL_ARCH="arm64"
    ;;
  *)
    export SYSTEM_ARCH="$(uname -m)"
    export DEB_ARCH="$SYSTEM_ARCH"
    export RPM_ARCH="$SYSTEM_ARCH"
    export URL_ARCH="$SYSTEM_ARCH"
    ;;
  esac

  if [ -f /etc/debian_version ]; then
    export DETECTED_DISTRO="debian"
    export DEBIAN_FRONTEND="noninteractive"
  elif [ -f /etc/arch-release ]; then
    export DETECTED_DISTRO="arch"
  elif [ -f /etc/fedora-release ]; then
    export DETECTED_DISTRO="fedora"
  elif [ "$(uname)" = "Darwin" ]; then
    export DETECTED_DISTRO="mac"
  else
    error "Unsupported distribution"
    exit 1
  fi
  if [ -f /proc/sys/kernel/osrelease ]; then
    if [ "$(uname)" != "Darwin" ] && [ -r /proc/sys/kernel/osrelease ] && grep -qEi "(Microsoft|WSL)" /proc/sys/kernel/osrelease 2>/dev/null; then
      export IS_WSL="true"
      touch ~/.hushlogin
    fi
  fi
}

package_manager() {
  case "$DETECTED_DISTRO" in
  "debian")
    if [ "$DISTRO_ID" = "ubuntu" ]; then
      for REPO in "main" "universe" "restricted" "multiverse"; do
        if ! grep -q "$REPO" /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null \
          && ! grep -q "$REPO" /etc/apt/sources.list 2>/dev/null; then
          sudo add-apt-repository -y "$REPO"
        fi
      done
    fi
    ensure_packages "apt-transport-https ca-certificates gnupg-agent software-properties-common"
    ;;
  "arch")
    ensure_packages "multilib"
    if ! command -v yay >/dev/null 2>&1; then
      info "Installing Yay..."
      sudo pacman -S --needed git base-devel && git clone "https://aur.archlinux.org/yay.git" && cd yay && makepkg -si
      cd ..
      rm -rfv yay
    fi
    ;;
  "fedora")
    ensure_packages "fedora-workstation-repositories dnf-plugins-core"
    if ! rpm -q "rpmfusion-free-release" > /dev/null 2>&1; then
      ensure_packages "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi
    if ! rpm -q "rpmfusion-nonfree-release" > /dev/null 2>&1; then
      ensure_packages "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi
    ;;
  "mac")
    if ! command -v brew >/dev/null 2>&1; then
      info "Installing Brew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      echo >>"$HOME/.zprofile"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    ;;
  esac
}

main() {
  detect_env
  package_manager
}

main "$@"

# Menu hook used when a feature script is run directly with sh.
menu() {
  return 0
}
