#!/bin/bash

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
