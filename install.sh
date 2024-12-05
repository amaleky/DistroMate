#!/bin/bash

if [ -f /etc/debian_version ]; then
  export DETECTED_DISTRO="debian"
  export DEBIAN_FRONTEND="noninteractive"
elif [ -f /etc/arch-release ]; then
  export DETECTED_DISTRO="arch"
elif [ "$(uname)" = "Darwin" ]; then
  export DETECTED_DISTRO="mac"
else
  echo "Unsupported distribution"
  exit 1
fi

if grep -qEi "(Microsoft|WSL)" /proc/sys/kernel/osrelease; then
  export IS_WSL="true"
fi

echo "Detected distribution: $DETECTED_DISTRO"

install_package_manager() {
  case $DETECTED_DISTRO in
    "debian")
      if ! command -v snap > /dev/null 2>&1; then
        if [ -n "$IS_WSL" ]; then
            echo "WSL detected, skipping snap install"
        else
          echo "Installing Snap..."
          sudo rm /etc/apt/preferences.d/no-snap.pref
          sudo apt update
          sudo apt install -y snapd
          sudo systemctl enable --now snapd.socket
          sudo ln -s /var/lib/snapd/snap /snap
        fi
      fi
      ;;
    "arch")
      if ! command -v yay > /dev/null 2>&1; then
        echo "Installing Yay..."
        sudo pacman -S --needed git base-devel && git clone "https://aur.archlinux.org/yay.git" && cd yay && makepkg -si
      fi
      if ! command -v snap > /dev/null 2>&1; then
        echo "Installing Snap..."
        git clone "https://aur.archlinux.org/snapd.git"
        cd snapd
        makepkg -si
        cd ..
        rm -rfv snapd
        sudo systemctl enable --now snapd.socket
        sudo ln -s /var/lib/snapd/snap /snap
      fi
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
  install_package_manager
  echo "Step $2"
  case $1 in
    1)
      echo "Upgrading System..."
      case $DETECTED_DISTRO in
        "debian")
          sudo apt update
          sudo snap refresh
          sudo apt dist-upgrade -y
          sudo apt autoremove --purge -y
          sudo apt install -y --fix-broken
          sudo dpkg --configure -a
          ;;
        "arch")
          yay -Scc
          sudo snap refresh
          yay -Syyuu --noconfirm --removemake --cleanafter
          ;;
        "mac")
          brew update
          brew upgrade
          brew cleanup
          ;;
      esac
      if [ -n "$IS_WSL" ]; then
          winget.exe upgrade --all
      fi
      ;;
    2)
      echo "Removing Bloatware..."
      BLOATWARE_PACKAGES=(
        # Games
        "aisleriot" "five-or-more" "four-in-a-row" "gnome-2048" "gnome-chess" "gnome-klotski" "gnome-mahjongg" "gnome-mines" "gnome-nibbles" "gnome-robots" "gnome-sudoku" "gnome-taquin" "gnome-tetravex" "hitori" "iagno" "lightsoff" "pegsolitaire" "quadrapassel" "swell-foop" "tali"
        # Apps
        "baobab" "brltty" "cheese" "cmake" "deja-dup" "duplicity" "empathy" "eos-apps-info" "eos-log-tool" "evince" "example-content" "gdebi*" "gnome-boxes" "gnome-calendar" "gnome-characters" "gnome-clocks" "gnome-console" "gnome-contacts" "gnome-font-viewer" "gnome-logs" "gnome-nettool" "gnome-screensaver" "gnome-snapshot" "gnome-sound-recorder" "gnome-usage" "gnome-video-effects" "gnome-weather" "imagemagick*" "landscape-common" "libreoffice*" "libsane" "mcp-account-manager-uoa" "meld" "mpv" "python3-uno" "reflector-simple" "remmina" "rhythmbox" "sane-utils" "seahorse" "shotwell" "simple-scan" "stoken" "telepathy-*" "thunderbird" "tilix" "totem" "transmission-gtk" "unity-scope-*" "usb-creator-gtk" "xterm" "yelp"
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
        esac
      done
      ;;
    3)
      echo "Installing Recommended Packages..."
      case $DETECTED_DISTRO in
        "debian")
          sudo add-apt-repository multiverse -y
          sudo apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common libfuse2 curl wget whois net-tools iperf3 unar unrar unzip vim nano git htop neofetch
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter curl wget whois net-tools iperf3 unar unrar unzip vim nano git htop neofetch
          ;;
        "mac")
          brew install wget
          brew install whois
          brew install unar
          brew install vim nano
          brew install htop neofetch
          brew install --cask stats
          ;;
      esac
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id RARLab.WinRAR
          winget.exe install -e --id Microsoft.PowerToys
          winget.exe install -e --id Microsoft.WindowsTerminal
          winget.exe install -e --id Microsoft.VCLibs.Desktop.14
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
          winget.exe install -e --id Microsoft.DotNet.Runtime.6
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
      ;;
    4)
      echo "Installing Drivers..."
      if [ -n "$IS_WSL" ]; then
          echo -e "\n NVIDIA: https://www.nvidia.com/en-us/software/nvidia-app/ \n"
          CPU_VENDOR=$(lscpu | grep 'Vendor ID' | awk '{print $3}')
          if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
              echo -e "\n INTEL: https://dsadata.intel.com/installer \n"
          elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
              echo -e "\n AMD: https://www.amd.com/en/support/download/drivers.html \n"
          fi
          read -r TMP
      else
        if command -v ubuntu-drivers > /dev/null 2>&1; then
          sudo ubuntu-drivers install
        fi
        if command -v nvidia-inst > /dev/null 2>&1; then
          nvidia-inst
        fi
      fi
      ;;
    5)
      case $(basename "$SHELL") in
        "zsh")
          echo "Installing oh-my-zsh"
          sh -c "$(wget -cO- "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh")"
          ;;
        "bash")
          echo "Installing oh-my-bash"
          bash -c "$(wget -cO- "https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh")"
          ;;
      esac
      ;;
    6)
      echo "Installing Docker, Kubernetes and Helm..."
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id Docker.DockerDesktop
          winget.exe install -e --id Docker.DockerCompose
      fi
      case $DETECTED_DISTRO in
        "debian")
          wget -cO- "https://get.docker.com/" | sh
          sudo apt install -y docker-compose
          sudo wget -cO /usr/bin/kubectl "https://dl.k8s.io/release/$(wget -cO- "https://dl.k8s.io/release/stable.txt")/bin/linux/amd64/kubectl"
          wget -cO- "https://get.helm.sh/helm-$(wget -cO- 'https://get.helm.sh/helm-latest-version')-linux-amd64.tar.gz" | sudo tar -xz --strip-components=1 -C /usr/bin/ linux-amd64/helm
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter docker docker-compose kubectl helm
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
    7)
      echo "Installing Latest Node Version..."
      wget -cO- "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | bash
      source ~/.nvm/nvm.sh
      nvm install --lts
      npm install --global yarn
      ;;
    8)
      echo "Installing Python3..."
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y python3 python3-pip
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter python3 python3-pip
          ;;
        "mac")
          brew install python3
          brew postinstall python3
          ;;
      esac
      chmod +x ~/bin -R
      mkdir -p ~/.pip
      echo -e "[global]\nuser = true" > ~/.pip/pip.conf
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id Python.Launcher
          winget.exe install -e --id Python.Python.3.9
      fi
      ;;
    9)
      echo "Installing Browsers..."
      BROWSER_OPTIONS=(
        "Chrome"
        "Firefox"
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
                  ln -s /opt/firefox/firefox /usr/bin/firefox
                  sudo wget -cO /usr/share/applications/firefox.desktop "https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop"
                  ;;
                "arch")
                  yay -S --noconfirm --needed --removemake --cleanafter firefox
                  ;;
                "mac")
                  brew install --cask firefox
                  ;;
              esac
            fi
            ;;
        esac
        menu
      done
      ;;
    10)
      echo "Installing Messengers..."
      MESSENGER_OPTIONS=(
        "Telegram"
        "WhatsApp"
        "Skype"
        "Slack"
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
                "mac")
                  brew install --cask slack
                  ;;
              esac
            fi
            ;;
        esac
        menu
      done
      ;;
    11)
      echo "Installing Jetbrains Toolbox..."
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id JetBrains.Toolbox
      else
        case $DETECTED_DISTRO in
          "debian")
            sudo apt install -y libfuse2 libxi6 libxrender1 libxtst6 mesa-utils libfontconfig libgtk-3-bin tar dbus-user-session
            JETBRAINS_RELEASES="$(wget -cO- "https://data.services.jetbrains.com/products?fields=name,code,releases.version,releases.downloads,releases.type")"
            TOOLBOX_URL="$(echo "$JETBRAINS_RELEASES" | grep -Eo 'https://download.jetbrains.com/toolbox/jetbrains-toolbox-[^"]+\.tar\.gz' | grep -vE 'arch|arm|exe|dmg|windows|mac' | head -n 1)"
            wget -cO- "$TOOLBOX_URL" | sudo tar -xz -C /opt
            sudo mv /opt/jetbrains-toolbox-* /opt/jetbrains-toolbox
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
    12)
      echo "Installing VSCode..."
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id Microsoft.VisualStudioCode
      else
        case $DETECTED_DISTRO in
          "debian")
            wget -cO /tmp/vscode.deb "https://go.microsoft.com/fwlink/?LinkID=760868"
            sudo apt install -y /tmp/vscode.deb
            rm -rfv /tmp/vscode.deb
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter visual-studio-code-bin
            ;;
          "mac")
            brew install --cask visual-studio-code
            ;;
        esac
      fi
      ;;
    13)
      echo "Installing Postman..."
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id Postman.Postman
      else
        case $DETECTED_DISTRO in
          "debian")
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
    14)
      echo "Installing VirtualBox..."
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
          "mac")
            brew install --cask virtualbox
            ;;
        esac
      fi
      ;;
    15)
      echo "Installing Anydesk..."
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id AnyDeskSoftwareGmbH.AnyDesk
      else
        case $DETECTED_DISTRO in
          "debian")
            BASE_URL="https://download.anydesk.com/linux/"
            LATEST_DEB=$(wget -cO- $BASE_URL | grep -o 'href="[^"]*_amd64.deb"' | sed 's/href="//' | sed 's/"//' | head -1)
            sudo wget -cO /tmp/anydesk.deb ${BASE_URL}${LATEST_DEB}
            sudo apt install -y /tmp/anydesk.deb
            rm -rfv /tmp/anydesk.deb
            ;;
          "arch")
            yay -S --noconfirm --needed --removemake --cleanafter anydesk-bin
            ;;
          "mac")
            brew install --cask anydesk
            ;;
        esac
      fi
      ;;
    16)
      echo "Installing OSB Studio..."
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
          "mac")
            brew install --cask obs
            ;;
        esac
      fi
      ;;
    17)
      echo "Installing Player..."
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
          "mac")
            brew install --cask iina
            ;;
        esac
      fi
      ;;
    18)
      echo "Installing Downloader..."
      if [ -n "$IS_WSL" ]; then
          winget.exe install -e --id Tonec.InternetDownloadManager
      else
        case $DETECTED_DISTRO in
          "debian" | "arch")
            wget -cO- "https://raw.githubusercontent.com/amir1376/ab-download-manager/master/scripts/install.sh" | bash
            ;;
          "mac")
            brew install --cask free-download-manager
            ;;
        esac
      fi
      ;;
    19)
      echo "Installing AdGuard..."
      wget -cO- "https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh" | sh -s -- -v
      ;;
    20)
      echo "Installing Samba..."
      case $DETECTED_DISTRO in
        "debian")
          sudo apt install -y samba
          ;;
        "arch")
          yay -S --noconfirm --needed --removemake --cleanafter samba
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
      echo -e "[share]\n    comment = Server Share\n    path = /srv/samba/share\n    browsable = yes\n    guest ok = yes\n    read only = no\n    create mask = 0755" | sudo tee -a /etc/samba/smb.conf
      sudo vim /etc/samba/smb.conf
      case $DETECTED_DISTRO in
        "debian")
          sudo systemctl restart smbd nmbd
          sudo systemctl enable smbd
          ;;
        "arch")
          sudo systemctl restart smb nmb
          sudo systemctl enable smb
          ;;
        "mac")
          sudo systemctl enable smb
          ;;
      esac
      ;;
    21)
      echo "Adding Battery Protection..."
      sudo sh -c "echo 80 > /sys/class/power_supply/BAT0/charge_control_start_threshold"
      sudo sh -c "echo 88 > /sys/class/power_supply/BAT0/charge_control_end_threshold"
      cat /sys/class/power_supply/BAT0/status
      ;;
    22)
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
        chmod 600 ~/.ssh/id_*
        chmod 644 ~/.ssh/id_*.pub
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
    23)
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
    "Upgrade" "Bloatware" "Recommended" "Driver" "OhMySH" "Docker" "NodeJS" "Python" "Browsers" "Messengers" "JetBrains" "VSCode" "Postman" "VirtualBox" "Anydesk" "OBS Studio" "Player" "Downloader" "AdGuard" "Samba" "Battery" "SSH" "Sudo" "Quit"
  )
  select CHOICE in "${OPTIONS[@]}"; do
    case $REPLY in
      *)
        run_commands $REPLY $CHOICE
        break
        ;;
    esac
  done
}

menu
