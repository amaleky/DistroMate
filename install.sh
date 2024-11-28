#!/bin/bash

if [ -f /etc/debian_version ]; then
    export DISTRO="debian"
elif [ -f /etc/arch-release ]; then
    export DISTRO="arch"
elif [ "$(uname)" = "Darwin" ]; then
    export DISTRO="mac"
else
    echo "Unsupported distribution"
    exit 1
fi

echo "Detected distribution: $DISTRO"

run_commands() {
    case $DISTRO in
        "arch")
            if ! command -v yay >/dev/null 2>&1; then
                sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
            fi
            ;;
        "mac")
            if ! command -v brew >/dev/null 2>&1; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            ;;
    esac
    case $1 in
        1)
            echo "Upgrading system..."
            case $DISTRO in
                "debian")
                    sudo apt update
                    sudo apt dist-upgrade -y
                    sudo apt autoremove --purge -y
                    sudo apt install -y --fix-broken
                    sudo dpkg --configure -a
                    ;;
                "arch")
                    yay -Scc
                    yay -Syyuu
                    ;;
                "mac")
                    brew update
                    brew upgrade
                    brew cleanup
                    ;;
            esac
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
            chmod 600 ~/.ssh/id_*
            chmod 644 ~/.ssh/id_*.pub
            ;;
        2)
            if ! command -v snap >/dev/null 2>&1; then
                echo "Removing Snap..."
                for pkg in $(snap list | awk 'NR>1 {print $1}' | grep -vE '^(core|snapd|bare)$'); do sudo snap remove --purge "$pkg"; done
                for pkg in $(snap list | awk 'NR>1 {print $1}'); do sudo snap remove --purge "$pkg"; done
                sudo apt purge -y --autoremove snapd gnome-software-plugin-snap
                sudo rm -rfv ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd /root/snap
                sudo apt-mark hold snapd
                echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/no-snap.pref
                sudo chown root:root /etc/apt/preferences.d/no-snap.pref
                if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
                    sudo apt install -y --install-suggests gnome-software
                fi
            else
                echo "Snap Is Already Removed"
            fi
            ;;
        3)
            echo "Installing Recommended Packages..."
            case $DISTRO in
                "debian")
                    sudo apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common libfuse2
                    sudo apt install -y curl wget net-tools iperf3
                    sudo apt install -y unar unzip
                    sudo apt install -y vim nano
                    sudo apt install -y git
                    sudo apt install -y htop
                    sudo apt install -y openvpn easy-rsa wireguard strongswan pptp-linux openfortivpn
                    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
                        sudo apt install -y chrome-gnome-shell gnome-tweaks
                    fi
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter curl wget net-tools iperf3
                    yay -S --noconfirm --needed --removemake --cleanafter unar unzip
                    yay -S --noconfirm --needed --removemake --cleanafter vim nano
                    yay -S --noconfirm --needed --removemake --cleanafter htop
                    yay -S --noconfirm --needed --removemake --cleanafter openvpn easy-rsa wireguard strongswan pptp-linux openfortivpn
                    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
                        yay -S --noconfirm --needed --removemake --cleanafter chrome-gnome-shell gnome-tweaks
                    fi
                    ;;
                "mac")
                    brew install wget
                    brew install unar
                    brew install htop neofetch
                    brew install --cask stats
                    brew install openvpn
                    brew install openfortivpn
                    ;;
            esac
            ;;
        4)
            echo "Unlocking Sudo Without Password..."
            sudo mkdir -p /etc/sudoers.d
            sudo rm -rfv /etc/sudoers.d/$USER
            sudo touch /etc/sudoers.d/$USER
            echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/$USER
            ;;
        5)
            echo "Installing Docker, Kubernetes and Helm..."
            case $DISTRO in
                "debian")
                    curl -sSL https://get.docker.com/ | sh
                    sudo usermod -aG docker $USER
                    dockerd-rootless-setuptool.sh install
                    sudo apt install -y docker-compose
                    curl -L -o /tmp/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
                    rm -rfv /tmp/kubectl
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
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
            ;;
        6)
            echo "Installing Latest Node Version..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
            source ~/.nvm/nvm.sh
            nvm install --lts
            npm install --global yarn
            ;;
        7)
            echo "Installing Python3..."
            case $DISTRO in
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
            chmod +x /home/$USER/bin -R
            mkdir -p ~/.pip && echo -e "[global]\nuser = true" >> ~/.pip/pip.conf
            ;;
        8)
            echo "Installing Chrome..."
            case $DISTRO in
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
        9)
            echo "Installing Webstorm..."
            case $DISTRO in
                "debian")
                    JETBRAINS_RELEASES=$(curl -s "https://data.services.jetbrains.com/products?fields=name,code,releases.version,releases.downloads,releases.type")
                    WEBSTORM_URL=$(echo "$JETBRAINS_RELEASES" | grep -Eo 'https://download.jetbrains.com/webstorm/WebStorm-[^"]+\.tar\.gz' | grep -vE 'arch|exe|dmg' | head -n 1)
                    curl -L -o /tmp/WebStorm.tar.gz $WEBSTORM_URL
                    sudo rm -rfv /opt/WebStorm
                    sudo tar xzf /tmp/WebStorm.tar.gz -C /opt/
                    sudo mv /opt/WebStorm-* /opt/WebStorm
                    rm -rfv /tmp/WebStorm.tar.gz
                    /opt/WebStorm/bin/webstorm
                    echo "Your vmoptions is: $(ls ~/.config/JetBrains/WebStorm*/webstorm64.vmoptions)"
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter webstorm webstorm-jre
                    echo "Your vmoptions is: $(ls ~/.config/JetBrains/WebStorm*/webstorm64.vmoptions)"
                    ;;
                "mac")
                    brew install --cask webstorm
                    echo "Your vmoptions is: $(ls ~/Library/Application\ Support/JetBrains/WebStorm*/webstorm.vmoptions)"
                    ;;
            esac
            sudo rm -rfv /etc/sysctl.d/idea.conf
            echo -e "fs.inotify.max_user_instances = 1024\nfs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/idea.conf
            sudo sysctl -p --system
            ;;
        10)
            echo "Installing VSCode..."
            case $DISTRO in
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
        11)
            echo "Installing Postman..."
            case $DISTRO in
                "debian")
                    curl -L -o /tmp/postman.tar.gz https://dl.pstmn.io/download/latest/linux_64
                    sudo tar -xzf /tmp/postman.tar.gz -C /usr/local/bin
                    rm -rfv /tmp/postman.tar.gz
                    echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Postman\nExec=/usr/local/bin/Postman/app/Postman %U\nIcon=/usr/local/bin/Postman/app/resources/app/assets/icon.png\nTerminal=false\nType=Application\nCategories=Development;" | sudo tee /usr/share/applications/postman.desktop
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter postman-bin
                    ;;
                "mac")
                    brew install --cask postman
                    ;;
            esac
            ;;
        12)
            echo "Installing VirtualBox..."
            case $DISTRO in
                "debian")
                    sudo apt install -y virtualbox virtualbox-ext-pack virtualbox-dkms
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter virtualbox virtualbox-host-dkms
                    ;;
                "mac")
                    brew install --cask virtualbox
                    ;;
            esac
            ;;
        13)
            echo "Installing Anydesk..."
            case $DISTRO in
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
        14)
            echo "Installing OSB Studio..."
            case $DISTRO in
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
        15)
            echo "Installing Player..."
            case $DISTRO in
                "debian")
                    sudo apt install -y mpv
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter mpv
                    ;;
                "mac")
                    brew install --cask iina
                    ;;
            esac
            ;;
        16)
            echo "Installing Downloader..."
            case $DISTRO in
                "debian" | "arch")
                    curl -fsSL https://raw.githubusercontent.com/amir1376/ab-download-manager/master/scripts/install.sh | bash
                    ;;
                "mac")
                    brew install --cask free-download-manager
                    ;;
            esac
            ;;
        17)
            echo "Installing AdGuard..."
            curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
            ;;
        18)
            echo "Installing Samba..."
            case $DISTRO in
                "debian")
                    sudo apt install -y samba
                    sudo systemctl restart smbd nmbd
                    sudo systemctl enable smbd
                    ;;
                "arch")
                    yay -S --noconfirm --needed --removemake --cleanafter samba
                    sudo systemctl restart smb nmb
                    sudo systemctl enable smb
                    ;;
                "mac")
                    brew install --cask samba
                    sudo systemctl enable smb
                    ;;
            esac
            echo "Enter your Samba User: ";
            read SMB_USER
            sudo useradd $SMB_USER
            sudo passwd $SMB_USER
            sudo smbpasswd -a $SMB_USER
            echo -e "[share]\n    comment = Server Share\n    path = /srv/samba/share\n    browsable = yes\n    guest ok = yes\n    read only = no\n    create mask = 0755" | sudo tee -a /etc/samba/smb.conf
            sudo vim /etc/samba/smb.conf
            ;;
        *)
            exit 0
            ;;
    esac
}

while true; do
    PS3='Enter your Option: '
    options=(
        "Upgrade"
        "Bloatware"
        "Recommended"
        "Sudo Unlock"
        "Docker"
        "NodeJS"
        "Python"
        "Chrome"
        "Webstorm"
        "VSCode"
        "Postman"
        "VirtualBox"
        "Anydesk"
        "OBS Studio"
        "Player"
        "Downloader"
        "AdGuard"
        "Samba"
        "Quit"
    )
    select choice in "${options[@]}"; do
        case $REPLY in
            *)
                run_commands $distro $REPLY
                break
                ;;
        esac
    done
done
