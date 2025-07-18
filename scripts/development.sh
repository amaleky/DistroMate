#!/bin/bash

main() {
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
      if command -v dockerd-rootless-setuptool.sh >/dev/null 2>&1; then
        dockerd-rootless-setuptool.sh install
      fi
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
          /opt/jetbrains-toolbox/bin/jetbrains-toolbox &
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
      if [ -n "$IS_WSL" ]; then
        echo "Run this command as Administrator: "
        echo "Set-ExecutionPolicy RemoteSigned"
        read OK
        winget.exe install -e --id CoreyButler.NVMforWindows
        nvm.exe on
        nvm.exe install --lts
        npm.exe install --global yarn
      fi
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
      if [ -e ~/bin ]; then
        chmod -v +x ~/bin -R
      fi
      mkdir -p ~/.pip
      echo -e "[global]\nuser = true" >~/.pip/pip.conf
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
}

main "$@"
