#!/bin/bash

main() {
  case "$DETECTED_DISTRO" in
  "debian")
    ensure_packages "apt-transport-https ca-certificates gnupg-agent software-properties-common uidmap inetutils-telnet netcat-openbsd"
    if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
      ensure_packages "gnome-terminal chrome-gnome-shell gnome-tweaks software-properties-gtk"
    fi
    ;;
  "arch")
    ensure_packages "multilib ffmpeg util-linux inetutils gnu-netcat"
    fc-cache --force
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now systemd-resolved
    if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
      ensure_packages "gstreamer-plugins-bad gstreamer-plugins-ugly ttf-mscorefonts-installer noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji ttf-ms-fonts vazirmatn-fonts ttf-jetbrains-mono gnome-terminal power-profiles-daemon gnome-browser-connector gnome-tweaks gnome-shell-extension-appindicator"
      sudo systemctl enable --now power-profiles-daemon
    fi
    ;;
  esac

  ensure_packages "wget whois traceroute iperf3 unar unzip vim nano htop nvtop jq"

  case "$DETECTED_DISTRO" in
  "mac")
    ensure_packages "font-jetbrains-mono" "--cask"
    ;;
  *)
    ensure_packages "git curl net-tools dnsutils"
    ;;
  esac

  if [ "$IS_WSL" == "true" ]; then
    winget.exe install -e --id Microsoft.DirectX
    winget.exe install -e --id Microsoft.DotNet.DesktopRuntime.6
    winget.exe install -e --id Microsoft.DotNet.DesktopRuntime.7
    winget.exe install -e --id Microsoft.DotNet.DesktopRuntime.8
    winget.exe install -e --id Microsoft.DotNet.DesktopRuntime.9
    winget.exe install -e --id Microsoft.DotNet.Runtime.6
    winget.exe install -e --id Microsoft.DotNet.Runtime.7
    winget.exe install -e --id Microsoft.DotNet.Runtime.8
    winget.exe install -e --id Microsoft.DotNet.Runtime.9
    winget.exe install -e --id Microsoft.VCLibs.Desktop.14
    winget.exe install -e --id Microsoft.VCRedist.2005.x64
    winget.exe install -e --id Microsoft.VCRedist.2005.x86
    winget.exe install -e --id Microsoft.VCRedist.2008.x64
    winget.exe install -e --id Microsoft.VCRedist.2008.x86
    winget.exe install -e --id Microsoft.VCRedist.2010.x64
    winget.exe install -e --id Microsoft.VCRedist.2010.x86
    winget.exe install -e --id Microsoft.VCRedist.2012.x64
    winget.exe install -e --id Microsoft.VCRedist.2012.x86
    winget.exe install -e --id Microsoft.VCRedist.2013.x64
    winget.exe install -e --id Microsoft.VCRedist.2013.x86
    winget.exe install -e --id Microsoft.VCRedist.2015+.arm64
    winget.exe install -e --id Microsoft.VCRedist.2015+.x64
    winget.exe install -e --id Microsoft.VCRedist.2015+.x86
    winget.exe install -e --id Microsoft.VSTOR
    winget.exe install -e --id Microsoft.WindowsTerminal
    winget.exe install -e --id RARLab.WinRAR
    winget.exe install -e --id Git.Git
  else
    ensure_packages "xfsprogs btrfs-progs exfatprogs udftools f2fs-tools"
  fi

  sudo bash -c 'grep -qxF "net.core.default_qdisc = fq" /etc/sysctl.conf || echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf'
  sudo bash -c 'grep -qxF "net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf'
  sudo bash -c 'grep -qxF "fs.inotify.max_user_instances = 1024" /etc/sysctl.d/idea.conf || echo "fs.inotify.max_user_instances = 1024" >> /etc/sysctl.d/idea.conf'
  sudo bash -c 'grep -qxF "fs.inotify.max_user_watches = 524288" /etc/sysctl.d/idea.conf || echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.d/idea.conf'
  sudo sysctl -p --system

  case "$(basename "$SHELL")" in
  "zsh")
    if [ ! -d ~/.oh-my-zsh ]; then
      info "Installing oh-my-zsh"
      sh -c "$(wget -cO- "https://github.com/ohmyzsh/ohmyzsh/raw/master/tools/install.sh")"
    fi
    ;;
  "bash")
    if [ ! -d ~/.oh-my-bash ]; then
      info "Installing oh-my-bash"
      bash -c "$(wget -cO- "https://github.com/ohmybash/oh-my-bash/raw/master/tools/install.sh")"
    fi
    ;;
  esac
}

main "$@"
