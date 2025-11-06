#!/bin/bash

# Colors for terminal output
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"
readonly NC="\033[0m" # No Color

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local options="[y/N]"
  [ "$default" = "y" ] && options="[Y/n]"

  read -r -p "$prompt $options: " response
  response="${response:-$default}"
  [[ $response =~ ^[Yy] ]]
}

ensure_packages() {
  local PACKAGES=$1
  local FLAGS=$2

  info "Installing $PACKAGES..."

  case "$DETECTED_DISTRO" in
    "debian")
      for PACKAGE in $PACKAGES; do
        sudo apt install -y $FLAGS $PACKAGE
      done
      ;;
    "arch")
      yay -S --noconfirm --needed --removemake --cleanafter $FLAGS $PACKAGES
      ;;
    "fedora")
      sudo dnf install -y --skip-unavailable $FLAGS $PACKAGES
      ;;
    "mac")
      brew install $FLAGS $PACKAGES
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
      brew uninstall --zap "$PACKAGE"
      ;;
    esac
  done
}

detect_env() {
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
  if grep -qEi "(Microsoft|WSL)" /proc/sys/kernel/osrelease; then
    export IS_WSL="true"
    touch ~/.hushlogin
  fi
}

package_manager() {
  case "$DETECTED_DISTRO" in
  "debian")
    for REPO in "main" "universe" "restricted" "multiverse"; do
      if ! grep -q "$REPO" /etc/apt/sources.list.d/ubuntu.sources && ! grep -q "$REPO" /etc/apt/sources.list; then
        sudo add-apt-repository -y "$REPO"
      fi
    done
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
      /bin/bash -c "$(wget -cO- "https://github.com/Homebrew/install/raw/HEAD/install.sh")"
      echo >>"$HOME/.zproAPP_ICON"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zproAPP_ICON"
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
