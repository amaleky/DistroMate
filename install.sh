#!/bin/bash

if [ -f /etc/debian_version ]; then
    export DETECTED_DISTRO="debian"
    export DEBIAN_FRONTEND=noninteractive
elif [ -f /etc/arch-release ]; then
    export DETECTED_DISTRO="arch"
elif [ "$(uname)" = "Darwin" ]; then
    export DETECTED_DISTRO="mac"
else
    echo "Unsupported distribution"
    exit 1
fi

echo "Detected distribution: $DETECTED_DISTRO"

install_package_manager() {
    case $DETECTED_DISTRO in
        "debian")
            if ! command -v snap >/dev/null 2>&1; then
                echo "Installing Snap..."
                sudo rm /etc/apt/preferences.d/no-snap.pref
                sudo apt update
                sudo apt install -y snapd
                sudo systemctl enable --now snapd.socket
                sudo ln -s /var/lib/snapd/snap /snap
            fi
            ;;
        "arch")
            if ! command -v yay >/dev/null 2>&1; then
                echo "Installing Yay..."
                sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
            fi
            if ! command -v snap >/dev/null 2>&1; then
                echo "Installing Snap..."
                git clone https://aur.archlinux.org/snapd.git
                cd snapd
                makepkg -si
                cd .. snapd
                rm -rfv
                sudo systemctl enable --now snapd.socket
                sudo ln -s /var/lib/snapd/snap /snap
            fi
            ;;
        "mac")
            if ! command -v brew >/dev/null 2>&1; then
                echo "Installing Brew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
            ;;
        2)
            echo "Removing Bloatware..."
            BLOATWARE_PACKAGES=(
                # Games
                "aisleriot"
                "five-or-more"
                "four-in-a-row"
                "gnome-2048"
                "gnome-chess"
                "gnome-klotski"
                "gnome-mahjongg"
                "gnome-mines"
                "gnome-nibbles"
                "gnome-robots"
                "gnome-sudoku"
                "gnome-taquin"
                "gnome-tetravex"
                "hitori"
                "iagno"
                "lightsoff"
                "pegsolitaire"
                "quadrapassel"
                "swell-foop"
                "tali"
                # Apps
                "baobab"
                "cmake"
                "deja-dup"
                "eos-apps-info"
                "eos-log-tool"
                "evince"
                "gnome-boxes"
                "gnome-calendar"
                "gnome-characters"
                "gnome-clocks"
                "gnome-console"
                "gnome-font-viewer"
                "gnome-logs"
                "gnome-snapshot"
                "gnome-usage"
                "gnome-weather"
                "libreoffice*"
                "meld"
                "mpv"
                "reflector-simple"
                "remmina"
                "rhythmbox"
                "seahorse"
                "shotwell"
                "simple-scan"
                "stoken"
                "thunderbird"
                "totem"
                "transmission-gtk"
                "usb-creator-gtk"
                "vlc"
                "xterm"
                "yelp"
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
                    sudo apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common libfuse2 curl wget net-tools iperf3 unar unzip vim nano git htop neofetch
                    if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
                        sudo apt install -y chrome-gnome-shell gnome-tweaks software-properties-gtk
                    fi
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter curl wget net-tools iperf3 unar unzip vim nano git htop neofetch
                    if [[ "$XDG_CURRENT_DESKTOP" = *GNOME* ]]; then
                        yay -S --noconfirm --needed --removemake --cleanafter chrome-gnome-shell gnome-tweaks software-properties-gtk
                    fi
                    ;;
                "mac")
                    brew install wget
                    brew install unar
                    brew install vim nano
                    brew install htop neofetch
                    brew install --cask stats
                    ;;
            esac
            ;;
        4)
            echo "Installing Drivers..."
            if command -v ubuntu-drivers >/dev/null 2>&1; then
                sudo ubuntu-drivers install
            fi
            if command -v nvidia-inst >/dev/null 2>&1; then
                nvidia-inst
            fi
            ;;
        5)
            case $(basename "$SHELL") in
                "zsh")
                    echo "Installing oh-my-zsh"
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
                    ;;
                "bash")
                    echo "Installing oh-my-bash"
                    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
                    ;;
            esac
            ;;
        6)
            echo "Installing Docker, Kubernetes and Helm..."
            case $DETECTED_DISTRO in
                "debian")
                    curl -sSL https://get.docker.com/ | sh
                    sudo apt install -y docker-compose

                    curl -L -o /tmp/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    mv -f /tmp/kubectl /usr/bin/
                    chmod +x /usr/bin/kubectl
                    rm -rfv /tmp/kubectl

                    curl -L -o /tmp/helm.tar.gz https://get.helm.sh/helm-$(curl -L -s https://get.helm.sh/helm-latest-version)-linux-amd64.tar.gz
                    tar -xzf /tmp/helm.tar.gz -C /tmp
                    mv -f /tmp/linux-amd64/helm /usr/bin/
                    chmod +x /usr/bin/helm
                    rm -rfv /tmp/helm.tar.gz /tmp/linux-amd64
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
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
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
                        case $DETECTED_DISTRO in
                            "debian")
                                curl -L -o /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
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
                        ;;
                    "Firefox")
                        case $DETECTED_DISTRO in
                            "debian")
                                wget -O /tmp/firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
                                sudo tar xjf /tmp/firefox.tar.bz2 -C /opt
                                ln -s /opt/firefox/firefox /usr/bin/firefox
                                sudo rm -rfv /tmp/firefox.tar.bz2
                                sudo curl -L -o /usr/share/applications/firefox.desktop https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop
                                ;;
                            "arch")
                                yay -S --noconfirm --needed --removemake --cleanafter firefox
                                ;;
                            "mac")
                                brew install --cask firefox
                                ;;
                        esac
                        ;;
                esac
                menu;
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
                        case $DETECTED_DISTRO in
                            "debian")
                                wget -O /tmp/telegram.tar.xz https://telegram.org/dl/desktop/linux
                                sudo tar -xf /tmp/telegram.tar.xz -C /opt
                                ;;
                            "arch")
                                yay -S --noconfirm --needed --removemake --cleanafter telegram-desktop
                                ;;
                            "mac")
                                brew install --cask telegram
                                ;;
                        esac
                        ;;
                    "WhatsApp")
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
                        ;;
                    "Skype")
                        case $DETECTED_DISTRO in
                            "debian")
                                curl -L -o /tmp/skype.deb https://go.skype.com/skypeforlinux-64.deb
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
                        ;;
                    "Slack")
                        case $DETECTED_DISTRO in
                            "debian")
                                SLACK_URL=$(curl -s "https://slack.com/downloads/instructions/linux?ddl=1&build=deb" | grep -Eo 'https://downloads.slack-edge.com/desktop-releases/linux/x64/[^"]+/slack-desktop-[^"]+-amd64.deb' | head -n 1)
                                echo "Downloading $SLACK_URL..."
                                curl -L -o /tmp/slack.deb "$SLACK_URL"
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
                        ;;
                esac
                menu;
            done
            ;;
        11)
            echo "Installing Jetbrains Toolbox..."
            case $DETECTED_DISTRO in
                "debian")
                    sudo apt install -y libfuse2 libxi6 libxrender1 libxtst6 mesa-utils libfontconfig libgtk-3-bin tar dbus-user-session
                    JETBRAINS_RELEASES=$(curl -s "https://data.services.jetbrains.com/products?fields=name,code,releases.version,releases.downloads,releases.type")
                    TOOLBOX_URL=$(echo "$JETBRAINS_RELEASES" | grep -Eo 'https://download.jetbrains.com/toolbox/jetbrains-toolbox-[^"]+\.tar\.gz' | grep -vE 'arch|arm|exe|dmg|windows|mac' | head -n 1)
                    echo "Downloading $TOOLBOX_URL..."
                    curl -L -o /tmp/jetbrains-toolbox.tar.gz $TOOLBOX_URL
                    sudo tar xzf /tmp/jetbrains-toolbox.tar.gz -C /opt
                    sudo mv /opt/jetbrains-toolbox-* /opt/jetbrains-toolbox
                    rm -rfv /tmp/jetbrains-toolbox.tar.gz
                    /opt/jetbrains-toolbox/jetbrains-toolbox &
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter jetbrains-toolbox
                    ;;
                "mac")
                    brew install --cask jetbrains-toolbox
                    ;;
            esac
            sudo rm -rfv /etc/sysctl.d/idea.conf
            echo -e "fs.inotify.max_user_instances = 1024\nfs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/idea.conf
            sudo sysctl -p --system
            ;;
        12)
            echo "Installing VSCode..."
            case $DETECTED_DISTRO in
                "debian")
                    curl -L -o /tmp/vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
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
            ;;
        13)
            echo "Installing Postman..."
            case $DETECTED_DISTRO in
                "debian")
                    curl -L -o /tmp/postman.tar.gz https://dl.pstmn.io/download/latest/linux_64
                    sudo tar -xzf /tmp/postman.tar.gz -C /opt
                    rm -rfv /tmp/postman.tar.gz
                    echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Postman\nExec=/opt/Postman/app/Postman %U\nIcon=/opt/Postman/app/resources/app/assets/icon.png\nTerminal=false\nType=Application\nCategories=Development;" | sudo tee /usr/share/applications/postman.desktop
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter postman-bin
                    ;;
                "mac")
                    brew install --cask postman
                    ;;
            esac
            ;;
        14)
            echo "Installing VirtualBox..."
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
            ;;
        15)
            echo "Installing Anydesk..."
            case $DETECTED_DISTRO in
                "debian")
                    BASE_URL="https://download.anydesk.com/linux/"
                    LATEST_DEB=$(curl -s $BASE_URL | grep -o 'href="[^"]*_amd64.deb"' | sed 's/href="//' | sed 's/"//' | head -1)
                    curl -L -o /tmp/anydesk.deb ${BASE_URL}${LATEST_DEB}
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
            ;;
        16)
            echo "Installing OSB Studio..."
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
            ;;
        17)
            echo "Installing Player..."
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
            ;;
        18)
            echo "Installing Downloader..."
            case $DETECTED_DISTRO in
                "debian" | "arch")
                    curl -fsSL https://raw.githubusercontent.com/amir1376/ab-download-manager/master/scripts/install.sh | bash
                    ;;
                "mac")
                    brew install --cask free-download-manager
                    ;;
            esac
            ;;
        19)
            echo "Installing AdGuard..."
            curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
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
            echo "Enter Your Samba User: ";
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
                echo "Enter Your SSH Email: ";
                read SSH_EMAIL
                ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$SSH_EMAIL"
            fi
            if [ -z "$(git config --global user.name)" ]; then
                echo "Enter Your GIT Name: ";
                read GIT_NAME
                git config --global user.name "$GIT_NAME"
            fi
            if [ -z "$(git config --global user.email)" ]; then
                echo "Enter Your GIT Email: ";
                read GIT_EMAIL
                git config --global user.email "$GIT_EMAIL"
            fi
            echo "This Is Your SSH Key: "
            cat ~/.ssh/id_ed25519.pub
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
    PS3='Enter Your Option: '
    OPTIONS=(
        "Upgrade"
        "Bloatware"
        "Recommended"
        "Driver"
        "OhMySH"
        "Docker"
        "NodeJS"
        "Python"
        "Browsers"
        "Messengers"
        "JetBrains"
        "VSCode"
        "Postman"
        "VirtualBox"
        "Anydesk"
        "OBS Studio"
        "Player"
        "Downloader"
        "AdGuard"
        "Samba"
        "Battery"
        "SSH"
        "Sudo"
        "Quit"
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