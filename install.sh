#!/bin/bash

prepare() {
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
      sudo add-apt-repository main universe restricted multiverse -y
      ;;
    "arch")
      if ! command -v yay > /dev/null 2>&1; then
        echo "Installing Yay..."
        sudo pacman -S --needed git base-devel && git clone "https://aur.archlinux.org/yay.git" && cd yay && makepkg -si
      fi
      ;;
    "fedora")
      sudo dnf install -y fedora-workstation-repositories dnf-plugins-core
      sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
      sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
      ;;
    "mac")
      if ! command -v brew > /dev/null 2>&1; then
        echo "Installing Brew..."
        /bin/bash -c "$(wget -cO- "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")"
      fi
      ;;
  esac

}

run_commands() {
  echo "Step $1"
  case $1 in
    "Upgrade")
      echo "Upgrading System..."
      case $DETECTED_DISTRO in
        "debian")
          sudo apt update
          sudo snap refresh
          sudo apt dist-upgrade -y
          sudo do-release-upgrade
          ;;
        "arch")
          yay -Scc
          sudo snap refresh
          yay -Syyuu --noconfirm --removemake --cleanafter
          ;;
        "fedora")
          sudo dnf update -y
          ;;
        "mac")
          brew update
          brew upgrade
          ;;
      esac
      if [ -n "$IS_WSL" ]; then
        winget.exe upgrade --all
      fi
      ;;
    "Bloatware")
      echo "Removing Bloatware..."
      BLOATWARE_PACKAGES=(
        # Games
        "aisleriot" "five-or-more" "four-in-a-row" "gnome-2048" "gnome-chess" "gnome-klotski" "gnome-mahjongg" "gnome-mines" "gnome-nibbles" "gnome-robots" "gnome-sudoku" "gnome-taquin" "gnome-tetravex" "hitori" "iagno" "lightsoff" "pegsolitaire" "quadrapassel" "swell-foop" "tali"
        # Apps
        "baobab" "brltty" "cheese" "cmake" "deja-dup" "duplicity" "empathy" "eos-apps-info" "eos-log-tool" "evince" "example-content" "gdebi*" "gnome-abrt" "gnome-boxes" "gnome-calendar" "gnome-characters" "gnome-clocks" "gnome-console" "gnome-contacts" "gnome-font-viewer" "gnome-logs" "gnome-maps" "gnome-nettool" "gnome-screensaver" "gnome-snapshot" "gnome-sound-recorder" "gnome-tour" "gnome-usage" "gnome-video-effects" "gnome-weather" "imagemagick*" "landscape-common" "libreoffice*" "libsane" "mcp-account-manager-uoa" "mediawriter" "meld" "mpv" "python3-uno" "reflector-simple" "remmina" "rhythmbox" "sane-utils" "seahorse" "shotwell" "simple-scan" "snapshot" "stoken" "telepathy-*" "thunderbird" "tilix" "totem" "transmission-gtk" "unity-scope-*" "usb-creator-gtk" "xterm" "yelp"
      )
      for PACKAGE in "${BLOATWARE_PACKAGES[@]}"; do
        echo "Removing $PACKAGE..."
        case $DETECTED_DISTRO in
          "debian")
            sudo apt purge -y --autoremove $PACKAGE
            ;;
          "arch")
            yay -Rcnssu --noconfirm $PACKAGE
            ;;
          "fedora")
            sudo dnf remove -y $PACKAGE
            ;;
        esac
      done
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y --fix-broken
          sudo dpkg --configure -a
          sudo apt autoremove --purge -y
          sudo apt clean
          sudo apt autoclean
          ;;
        "arch")
          sudo yay -Sc
          ;;
        "fedora")
          sudo dnf autoremove -y
          sudo dnf clean all
          ;;
        "mac")
          brew cleanup
          ;;
      esac
      sudo truncate -s 0 /var/log/**/*.log ~/.local/share/xorg/*.log
      sudo rm -rfv /tmp/* ~/.viminfo ~/.local/share/Trash/* ~/.cache/mozilla/firefox/* ~/.cache/evolution/* ~/.cache/thumbnails/* ~/.local/share/recently-used.xbel ~/.local/share/gnome-shell/application_state ~/.local/share/gnome-shell/favorite-apps ~/.local/share/gnome-shell/searches/* ~/.local/share/gnome-shell/overview/*
      sudo docker system prune -a -f
      tracker3 reset -s -r
      ;;
    "Recommended")
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common curl wget whois net-tools dnsutils iperf3 unar unrar unzip vim nano git htop neofetch
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter curl wget whois net-tools dnsutils iperf3 unar unrar unzip vim nano git htop neofetch
          ;;
        "fedora")
          sudo dnf install -y --skip-unavailable curl wget whois net-tools dnsutils iperf3 unar unrar unzip vim nano git htop neofetch
          ;;
        "mac")
          brew install wget whois iperf3 unar unrar unzip vim nano htop neofetch
          brew install --cask stats
          ;;
      esac
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id RARLab.WinRAR
        winget.exe install -e --id Microsoft.PowerToys
        winget.exe install -e --id Microsoft.WindowsTerminal
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
      else
        case $DETECTED_DISTRO in
          "debian")
            sudo apt install -y ubuntu-restricted-extras libavcodec-extra
            if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
              sudo apt install -y gnome-terminal chrome-gnome-shell gnome-tweaks software-properties-gtk
            fi
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter multilib ffmpeg gstreamer-plugins-bad gstreamer-plugins-ugly ttf-mscorefonts-installer
            if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
              yay -S --noconfirm --needed --removemake --cleanafter gnome-terminal chrome-gnome-shell gnome-tweaks software-properties-gtk
            fi
            ;;
        esac
      fi
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
      ;;
    "Driver")
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y fwupd ubuntu-drivers-common
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter fwupd nvidia-inst
          ;;
        "fedora")
          sudo dnf install -y fwupd nvidia-gpu-firmware
          ;;
      esac
      if [ -n "$IS_WSL" ]; then
        echo -e "\n NVIDIA: https://www.nvidia.com/en-us/software/nvidia-app/ \n"
        CPU_VENDOR=$(lscpu | grep 'Vendor ID' | awk '{print $3}')
        if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
          echo -e "\n INTEL: https://dsadata.intel.com/installer \n"
        elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
          echo -e "\n AMD: https://www.amd.com/en/support/download/drivers.html \n"
        fi
      else
        if command -v ubuntu-drivers > /dev/null 2>&1; then
          sudo ubuntu-drivers install
        fi
        if command -v nvidia-inst > /dev/null 2>&1; then
          nvidia-inst
        fi
        if command -v fwupdmgr > /dev/null 2>&1; then
          sudo fwupdmgr refresh
          sudo fwupdmgr update
        fi
      fi
      ;;
    "Development")
      PROGRAMMING_OPTIONS=(
        "Docker" "VSCode" "JetBrains" "Postman" "NodeJS" "Python" "GoLang" "Dotnet"
      )
      select PROGRAMMING_CHOICE in "${PROGRAMMING_OPTIONS[@]}"; do
        echo "Installing $PROGRAMMING_CHOICE..."
        case $PROGRAMMING_CHOICE in
          "Docker")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Docker.DockerDesktop
              winget.exe install -e --id Docker.DockerCompose
            fi
            case $DETECTED_DISTRO in
              "debian")
                wget -cO- "https://get.docker.com/" | sh
                sudo apt install -y docker-compose
                sudo wget -cO /usr/bin/kubectl "https://dl.k8s.io/release/$(wget -cO- "https://dl.k8s.io/release/stable.txt")/bin/linux/amd64/kubectl"
                sudo chmod +x /usr/bin/kubectl
                wget -cO- "https://get.helm.sh/helm-$(wget -cO- 'https://get.helm.sh/helm-latest-version')-linux-amd64.tar.gz" | sudo tar -xz --strip-components=1 -C /usr/bin/ linux-amd64/helm
                ;;
              "arch")
                yay -S --noconfirm --needed --removemake --cleanafter docker docker-compose kubectl helm
                ;;
              "fedora")
                sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin helm kubernetes-client
                sudo systemctl start docker
                ;;
              "mac")
                brew install --cask docker
                brew install docker-compose
                brew install kubectl
                brew install helm
                ;;
            esac
            sudo usermod -aG docker $USER
            dockerd-rootless-setuptool.sh install
            ;;
          "VSCode")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Microsoft.VisualStudioCode
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO /tmp/vscode.deb "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
                  sudo apt install -y /tmp/vscode.deb
                  rm -rfv /tmp/vscode.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter visual-studio-code-bin
                  ;;
                "fedora")
                  wget -cO /tmp/vscode.rpm "https://update.code.visualstudio.com/latest/linux-rpm-x64/stable"
                  sudo dnf install -y /tmp/vscode.rpm
                  rm -rfv /tmp/vscode.rpm
                  ;;
                "mac")
                  brew install --cask visual-studio-code
                  ;;
              esac
            fi
            ;;
          "JetBrains")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id JetBrains.Toolbox
            else
              case $DETECTED_DISTRO in
                "debian" | "fedora")
                  if [ $DETECTED_DISTRO == "debian" ]; then
                    sudo apt install -y jq libfuse2 libxi6 libxrender1 libxtst6 mesa-utils libfontconfig libgtk-3-bin tar dbus-user-session
                  elif [ $DETECTED_DISTRO == "fedora" ]; then
                    sudo dnf install -y jq fuse fuse-libs
                  fi
                  TOOLBOX_URL="$(wget -cO- "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | jq -r ".TBA[0].downloads.linux.link")"
                  wget -cO- "$TOOLBOX_URL" | sudo tar -xz -C /opt
                  sudo rm -rfv /opt/jetbrains-toolbox
                  sudo mv -v /opt/jetbrains-toolbox-* /opt/jetbrains-toolbox
                  /opt/jetbrains-toolbox/jetbrains-toolbox &
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter jetbrains-toolbox
                  ;;
                "mac")
                  brew install --cask jetbrains-toolbox
                  ;;
              esac
            fi
            sudo rm -rfv /etc/sysctl.d/idea.conf
            echo -e "fs.inotify.max_user_instances = 1024\nfs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/idea.conf
            sudo sysctl -p --system
            ;;
          "Postman")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Postman.Postman
            else
              case $DETECTED_DISTRO in
                "debian" | "fedora")
                  wget -cO- "https://dl.pstmn.io/download/latest/linux_64" | sudo tar -xz -C /opt
                  echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Postman\nExec=/opt/Postman/app/Postman %U\nIcon=/opt/Postman/app/resources/app/assets/icon.png\nTerminal=false\nType=Application\nCategories=Development;" | sudo tee /usr/share/applications/postman.desktop
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter postman-bin
                  ;;
                "mac")
                  brew install --cask postman
                  ;;
              esac
            fi
            ;;
          "NodeJS")
            wget -cO- "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | bash
            source ~/.nvm/nvm.sh
            nvm install --lts
            npm install --global yarn
            ;;
          "Python")
            case $DETECTED_DISTRO in
              "debian")
                sudo apt install -y python3 python3-pip
                ;;
              "arch")
                yay -S --noconfirm --needed --removemake --cleanafter python3 python3-pip
                ;;
              "fedora")
                sudo dnf install -y python3 python3-pip
                ;;
              "mac")
                brew install python3
                brew postinstall python3
                ;;
            esac
            chmod -v +x ~/bin -R
            mkdir -p ~/.pip
            echo -e "[global]\nuser = true" > ~/.pip/pip.conf
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Python.Launcher
              winget.exe install -e --id Python.Python.3.9
            fi
            ;;
          "GoLang")
            case $DETECTED_DISTRO in
              "debian")
                sudo apt install -y golang-go
                ;;
              "arch")
                yay -S --noconfirm --needed --removemake --cleanafter go
                ;;
              "fedora")
                sudo dnf install -y golang
                ;;
              "mac")
                brew install go
                ;;
            esac
            ;;
          "Dotnet")
            case $DETECTED_DISTRO in
              "debian")
                sudo apt install -y dotnet8
                ;;
              "arch")
                yay -S --noconfirm --needed --removemake --cleanafter dotnet-sdk
                ;;
              "fedora")
                sudo dnf install -y dotnet8
                ;;
              "mac")
                brew install --cask dotnet-sdk
                ;;
            esac
            ;;
        esac
        menu
      done
      ;;
    "Browser")
      BROWSER_OPTIONS=(
        "Chrome" "Firefox" "Edge" "Brave"
      )
      select BROWSER_CHOICE in "${BROWSER_OPTIONS[@]}"; do
        echo "Installing $BROWSER_CHOICE..."
        case $BROWSER_CHOICE in
          "Chrome")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Google.Chrome
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
                  sudo apt install -y /tmp/google-chrome.deb
                  rm -rfv /tmp/google-chrome.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter google-chrome
                  ;;
                "fedora")
                  sudo dnf install -y google-chrome
                  ;;
                "mac")
                  brew install --cask google-chrome
                  ;;
              esac
            fi
            ;;
          "Firefox")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Mozilla.Firefox
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO- "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" | sudo tar -xj -C /opt
                  sudo ln -vs /opt/firefox/firefox /usr/bin/firefox
                  sudo wget -cO /usr/share/applications/firefox.desktop "https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop"
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter firefox
                  ;;
                "fedora")
                  sudo dnf install -y firefox
                  ;;
                "mac")
                  brew install --cask firefox
                  ;;
              esac
            fi
            ;;
          "Edge")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Microsoft.Edge
            else
              case $DETECTED_DISTRO in
                "debian")
                  BASE_URL="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/"
                  LATEST_DEB=$(wget -O- "$BASE_URL" | grep -oP '(?<=href=")[^/]*?_amd64\.deb' | sort -V | tail -n1)
                  wget -cO /tmp/edge.deb "${BASE_URL}${LATEST_DEB}"
                  sudo apt install -y /tmp/edge.deb
                  rm -rfv /tmp/edge.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter microsoft-edge-stable-bin
                  ;;
                "fedora")
                  BASE_URL="https://packages.microsoft.com/yumrepos/edge/Packages/m/"
                  LATEST_RPM=$(wget -O- "$BASE_URL" | grep -oP '(?<=href=")[^/]*?\.x86_64\.rpm' | sort -V | tail -n1)
                  wget -cO /tmp/edge.rpm "${BASE_URL}${LATEST_RPM}"
                  sudo dnf install -y /tmp/edge.rpm
                  rm -rfv /tmp/edge.rpm
                  ;;
                "mac")
                  brew install --cask microsoft-edge
                  ;;
              esac
            fi
            ;;
          "Brave")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Brave.Brave
            else
              case $DETECTED_DISTRO in
                "debian" | "fedora")
                  curl -fsS https://dl.brave.com/install.sh | sh
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter brave-bin
                  ;;
                "mac")
                  brew install --cask brave-browser
                  ;;
              esac
            fi
            ;;
        esac
        menu
      done
      ;;
    "Messenger")
      MESSENGER_OPTIONS=(
        "Telegram" "WhatsApp" "Skype" "Slack" "Discord" "Zoom"
      )
      select BROWSER_CHOICE in "${MESSENGER_OPTIONS[@]}"; do
        echo "Installing $BROWSER_CHOICE..."
        case $BROWSER_CHOICE in
          "Telegram")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Telegram.TelegramDesktop
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO- "https://telegram.org/dl/desktop/linux" | sudo tar -xJ -C /opt
                  /opt/Telegram/Telegram &
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter telegram-desktop
                  ;;
                "fedora")
                  sudo dnf install -y telegram-desktop
                  ;;
                "mac")
                  brew install --cask telegram
                  ;;
              esac
            fi
            ;;
          "WhatsApp")
            if [ -n "$IS_WSL" ]; then
              winget.exe install WhatsApp
            else
              case $DETECTED_DISTRO in
                "debian")
                  sudo snap install whatsapp-linux-desktop
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter whatsapp-for-linux
                  ;;
                "fedora")
                  sudo snap install whatsapp-electron
                  ;;
                "mac")
                  brew install --cask whatsapp
                  ;;
              esac
            fi
            ;;
          "Skype")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Microsoft.Skype
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO /tmp/skype.deb "https://go.skype.com/skypeforlinux-64.deb"
                  sudo apt install -y /tmp/skype.deb
                  rm -rfv /tmp/skype.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter skypeforlinux-bin
                  ;;
                "fedora")
                  sudo snap install skype
                  ;;
                "mac")
                  brew install --cask skype
                  ;;
              esac
            fi
            ;;
          "Slack")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id SlackTechnologies.Slack
            else
              case $DETECTED_DISTRO in
                "debian")
                  SLACK_URL="$(wget -cO- "https://slack.com/downloads/instructions/linux?ddl=1&build=deb" | grep -Eo 'https://downloads.slack-edge.com/desktop-releases/linux/x64/[^"]+/slack-desktop-[^"]+-amd64.deb' | head -n 1)"
                  wget -cO /tmp/slack.deb "$SLACK_URL"
                  sudo apt install -y /tmp/slack.deb
                  rm -rfv /tmp/slack.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter slack-desktop
                  ;;
                "fedora")
                  sudo snap install slack
                  ;;
                "mac")
                  brew install --cask slack
                  ;;
              esac
            fi
            ;;
          "Discord")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Discord.Discord
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                  sudo apt install -y /tmp/discord.deb
                  rm -rfv /tmp/discord.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter discord
                  ;;
                "fedora")
                  sudo dnf install -y discord
                  ;;
                "mac")
                  brew install --cask discord
                  ;;
              esac
            fi
            ;;
          "Zoom")
            if [ -n "$IS_WSL" ]; then
              winget.exe install -e --id Zoom.Zoom
            else
              case $DETECTED_DISTRO in
                "debian")
                  wget -cO /tmp/zoom.deb "https://zoom.us/client/latest/zoom_amd64.deb"
                  sudo apt install -y /tmp/zoom.deb
                  rm -rfv /tmp/zoom.deb
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter zoom
                  ;;
                "fedora")
                  wget -cO /tmp/zoom.rpm "https://cdn.zoom.us/prod/6.2.11.5069/zoom_x86_64.rpm"
                  sudo apt install -y /tmp/zoom.rpm
                  rm -rfv /tmp/zoom.rpm
                  ;;
                "mac")
                  brew install --cask zoom
                  ;;
              esac
            fi
            ;;
        esac
        menu
      done
      ;;
    "Player")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -i -e --id CodecGuide.K-LiteCodecPack.Full
      else
        case $DETECTED_DISTRO in
          "debian")
            sudo apt install -y vlc
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter vlc
            ;;
          "fedora")
            sudo dnf install -y vlc
            ;;
          "mac")
            brew install --cask iina
            ;;
        esac
      fi
      ;;
    "Downloader")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id Tonec.InternetDownloadManager
      else
        case $DETECTED_DISTRO in
          "debian" | "arch" | "fedora")
            wget -cO- "https://raw.githubusercontent.com/amir1376/ab-download-manager/master/scripts/install.sh" | bash
            ;;
          "mac")
            brew install --cask free-download-manager
            ;;
        esac
      fi
      ;;
    "VirtualBox")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id Oracle.VirtualBox
      else
        case $DETECTED_DISTRO in
          "debian")
            sudo apt install -y virtualbox virtualbox-dkms
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter virtualbox virtualbox-host-dkms
            ;;
          "fedora")
            sudo dnf install -y VirtualBox
            ;;
          "mac")
            brew install --cask virtualbox
            ;;
        esac
      fi
      ;;
    "Anydesk")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id AnyDeskSoftwareGmbH.AnyDesk
      else
        case $DETECTED_DISTRO in
          "debian")
            BASE_URL="https://download.anydesk.com/linux/"
            LATEST_DEB=$(wget -cO- $BASE_URL | grep -o 'href="[^"]*_amd64.deb"' | sed 's/href="//' | sed 's/"//' | head -1)
            wget -cO /tmp/anydesk.deb "${BASE_URL}${LATEST_DEB}"
            sudo apt install -y /tmp/anydesk.deb
            rm -rfv /tmp/anydesk.deb
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter anydesk-bin
            ;;
          "fedora")
            BASE_URL="https://download.anydesk.com/linux/"
            LATEST_RPM=$(wget -cO- $BASE_URL | grep -o 'href="[^"]*x86_64.rpm"' | sed 's/href="//' | sed 's/"//' | head -1)
            wget -cO /tmp/anydesk.rpm "${BASE_URL}${LATEST_RPM}"
            sudo dnf install -y /tmp/anydesk.rpm
            rm -rfv /tmp/anydesk.rpm
            ;;
          "mac")
            brew install --cask anydesk
            ;;
        esac
      fi
      ;;
    "OBS")
      if [ -n "$IS_WSL" ]; then
        winget.exe install -e --id OBSProject.OBSStudio
      else
        case $DETECTED_DISTRO in
          "debian")
            sudo apt install -y obs-studio
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter obs-studio
            ;;
          "fedora")
            sudo dnf install -y obs-studio
            ;;
          "mac")
            brew install --cask obs
            ;;
        esac
      fi
      ;;
    "AdGuard")
      wget -cO- "https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh" | sh -s -- -v
      ;;
    "Samba")
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y samba
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter samba
          ;;
        "mac")
          sudo dnf install -y samba
          ;;
        "mac")
          brew install --cask samba
          ;;
      esac
      echo "Enter Your Samba User: "
      read SMB_USER
      sudo useradd $SMB_USER
      sudo passwd $SMB_USER
      sudo smbpasswd -a $SMB_USER
      sudo usermod -g smbgroup $SMB_USER
      echo -e "[share]\n    comment = Server Share\n    path = /srv/samba/share\n    browsable = yes\n    guest ok = yes\n    read only = no\n    create mask = 0755" | sudo tee -a /etc/samba/smb.conf
      sudo vim /etc/samba/smb.conf
      case $DETECTED_DISTRO in
        "debian")
          sudo systemctl restart smbd nmbd
          sudo systemctl enable smbd
          ;;
        "arch" | "fedora")
          sudo systemctl restart smb nmb
          sudo systemctl enable smb nmb
          ;;
        "mac")
          sudo systemctl enable smb
          ;;
      esac
      ;;
    "Battery")
      echo "Adding Battery Protection..."
      sudo sh -c "echo 80 > /sys/class/power_supply/BAT0/charge_control_start_threshold"
      sudo sh -c "echo 88 > /sys/class/power_supply/BAT0/charge_control_end_threshold"
      cat /sys/class/power_supply/BAT0/status
      ;;
    "SSH")
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y git openssh-client
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter git openssh-client
          ;;
        "mac")
          brew install --cask git
          brew install --cask openssh-client
          ;;
      esac
      if [ -f ~/.ssh/id_*.pub ]; then
        echo "Changing SSH Keys Permission..."
        chmod -v 600 ~/.ssh/id_*
        chmod -v 644 ~/.ssh/id_*.pub
      else
        echo "Enter Your SSH Email: "
        read SSH_EMAIL
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$SSH_EMAIL"
      fi
      if [ -z "$(git config --global user.name)" ]; then
        echo "Enter Your GIT Name: "
        read GIT_NAME
        git config --global user.name "$GIT_NAME"
      fi
      if [ -z "$(git config --global user.email)" ]; then
        echo "Enter Your GIT Email: "
        read GIT_EMAIL
        git config --global user.email "$GIT_EMAIL"
      fi
      for PUBLIC_KEY in ~/.ssh/*.pub; do
        echo "This Is Your SSH Key ($PUBLIC_KEY): "
        cat "$PUBLIC_KEY"
      done
      ;;
    "Sudo")
      echo "Unlocking Sudo Without Password..."
      sudo mkdir -p /etc/sudoers.d
      sudo rm -rfv /etc/sudoers.d/$USER
      sudo touch /etc/sudoers.d/$USER
      echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/$USER
      ;;
    *)
      exit 0
      ;;
  esac
  menu
}

menu() {
  PS3="Enter Your Option: "
  OPTIONS=(
    "Upgrade" "Bloatware" "Recommended" "Driver" "Development" "Browser" "Messenger" "Player" "Downloader" "VirtualBox" "Anydesk" "OBS" "AdGuard" "Samba" "Battery" "SSH" "Sudo" "Quit"
  )
  select CHOICE in "${OPTIONS[@]}"; do
    run_commands "$CHOICE"
  done
}

prepare
menu
