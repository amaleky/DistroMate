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

ensure_packages() {
  local PACKAGES="$1"
  info "Installing package: $PACKAGES"
  case $DETECTED_DISTRO in
  "debian")
    sudo apt install -y "$PACKAGES"
    ;;
  "arch")
    yay -S --noconfirm --needed --removemake --cleanafter "$PACKAGES"
    ;;
  "fedora")
    sudo dnf install -y --skip-unavailable "$PACKAGES"
    ;;
  "mac")
    brew install "$PACKAGES"
    ;;
  esac
}

remove_packages() {
  local PACKAGES="$1"
  for PACKAGE in $PACKAGES; do
    echo "Removing $PACKAGE..."
    case $DETECTED_DISTRO in
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

main() {
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
      echo "Unsupported distribution"
      exit 1
    fi

    if grep -qEi "(Microsoft|WSL)" /proc/sys/kernel/osrelease; then
      export IS_WSL="true"
      touch ~/.hushlogin
    fi

    case $DETECTED_DISTRO in
    "debian")
      MOST_HAVE_PACKAGES=("ubuntu-restricted-extras" "libavcodec-extra")
      MISSING_PACKAGES=()
      for package in "${MOST_HAVE_PACKAGES[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
          MOST_HAVE_PACKAGES_IS_INSTALLED=false
          MISSING_PACKAGES+=("$package")
        fi
      done
      if [ "$MOST_HAVE_PACKAGES_IS_INSTALLED" == "false" ]; then
        sudo add-apt-repository main universe restricted multiverse -y
        sudo apt install -y "${MISSING_PACKAGES[@]}"
      fi
      ;;
    "arch")
      if ! command -v yay >/dev/null 2>&1; then
        echo "Installing Yay..."
        sudo pacman -S --needed git base-devel && git clone "https://aur.archlinux.org/yay.git" && cd yay && makepkg -si
        cd ..
        rm -rfv yay
      fi
      ;;
    "fedora")
      sudo dnf install -y fedora-workstation-repositories dnf-plugins-core
      sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
      sudo dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
      ;;
    "mac")
      if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Brew..."
        /bin/bash -c "$(wget -cO- "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")"
        echo >>"$HOME/.zproAPP_ICON"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zproAPP_ICON"
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      ;;
    esac
}

main "$@"
