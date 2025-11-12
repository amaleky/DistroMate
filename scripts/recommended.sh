#!/bin/bash

main() {
  COMMON_PACKAGES="wget whois traceroute iperf3 unar unzip vim nano htop jq"

  if [ "$DETECTED_DISTRO" != "mac" ]; then
    COMMON_PACKAGES="$COMMON_PACKAGES preload git curl net-tools dnsutils nvtop"
  fi

  case "$DETECTED_DISTRO" in
  "debian")
    ensure_packages "$COMMON_PACKAGES uidmap inetutils-telnet netcat-openbsd software-properties-gtk"
    ;;
  "fedora")
    ensure_packages "$COMMON_PACKAGES telnet nmap-ncat"
    ;;
  "arch")
    ensure_packages "$COMMON_PACKAGES power-profiles-daemon util-linux inetutils gnu-netcat"
    sudo systemctl enable --now systemd-resolved
    sudo systemctl enable --now power-profiles-daemon
    ;;
  esac

  sudo systemctl enable preload
  sudo systemctl start preload

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
      sh -c "$(wget -cO- "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh")"
    fi
    ;;
  "bash")
    if [ ! -d ~/.oh-my-bash ]; then
      info "Installing oh-my-bash"
      bash -c "$(wget -cO- "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh")"
    fi
    ;;
  esac
}

main "$@"
