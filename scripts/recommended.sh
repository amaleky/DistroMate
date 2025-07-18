#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    winget.exe install -e --id Microsoft.DotNet.Runtime.6
    winget.exe install -e --id Microsoft.VCLibs.Desktop.14
    winget.exe install -e --id Microsoft.VCRedist.2005.x86
    winget.exe install -e --id Microsoft.VCRedist.2008.x64
    winget.exe install -e --id Microsoft.VCRedist.2008.x86
    winget.exe install -e --id Microsoft.VCRedist.2010.x64
    winget.exe install -e --id Microsoft.VCRedist.2010.x86
    winget.exe install -e --id Microsoft.VCRedist.2012.x64
    winget.exe install -e --id Microsoft.VCRedist.2012.x86
    winget.exe install -e --id Microsoft.VCRedist.2013.x64
    winget.exe install -e --id Microsoft.VCRedist.2013.x86
    winget.exe install -e --id Microsoft.VCRedist.2015+.x64
    winget.exe install -e --id Microsoft.VCRedist.2015+.x86
    winget.exe install -e --id Microsoft.VSTOR
    winget.exe install -e --id Microsoft.WindowsTerminal
    winget.exe install -e --id Oracle.JavaRuntimeEnvironment
    winget.exe install -e --id RARLab.WinRAR
    winget.exe install -e --id Git.Git
  fi
  case $DETECTED_DISTRO in
  "debian")
    sudo apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common uidmap curl wget whois net-tools dnsutils iperf3 unar unzip vim nano git htop nvtop neofetch
    if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
      sudo apt install -y gnome-terminal chrome-gnome-shell gnome-tweaks software-properties-gtk
    fi
    ;;
  "arch")
    yay -S --noconfirm --needed --removemake --cleanafter curl wget whois net-tools dnsutils iperf3 unar unzip vim nano git htop nvtop neofetch multilib ffmpeg gstreamer-plugins-bad gstreamer-plugins-ugly ttf-mscorefonts-installer noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji ttf-ms-fonts vazirmatn-fonts ttf-jetbrains-mono
    fc-cache --force
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now systemd-resolved
    if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
      yay -S --noconfirm --needed --removemake --cleanafter gnome-terminal power-profiles-daemon gnome-browser-connector gnome-tweaks gnome-shell-extension-appindicator
      sudo systemctl enable --now power-profiles-daemon
    fi
    ;;
  "fedora")
    sudo dnf install -y --skip-unavailable curl wget whois net-tools dnsutils iperf3 unzip vim nano git htop nvtop neofetch
    ;;
  "mac")
    brew install wget whois iperf3 unar unzip vim nano htop neofetch
    brew install --cask font-jetbrains-mono
    ;;
  esac
  case $(basename "$SHELL") in
  "zsh")
    if [ ! -d ~/.oh-my-zsh ]; then
      echo "Installing oh-my-zsh"
      sh -c "$(wget -cO- "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh")"
    fi
    ;;
  "bash")
    if [ ! -d ~/.oh-my-bash ]; then
      echo "Installing oh-my-bash"
      bash -c "$(wget -cO- "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh")"
    fi
    ;;
  esac
}

main "$@"
