#!/bin/bash

main() {
  PROGRAMMING_OPTIONS=(
    "Docker" "VSCode" "JetBrains" "Postman" "NodeJS" "Bun" "Python" "GoLang" "Dotnet"
  )

  select PROGRAMMING_CHOICE in "${PROGRAMMING_OPTIONS[@]}"; do
    info "Installing $PROGRAMMING_CHOICE..."
    case "$PROGRAMMING_CHOICE" in
    "Docker")
      if [ "$IS_WSL" == "true" ]; then
        winget.exe install -e --id Docker.DockerDesktop
        winget.exe install -e --id Docker.DockerCompose
      fi
      case "$DETECTED_DISTRO" in
      "debian")
        wget -cO- "https://get.docker.com/" | sh
        ensure_packages "docker-compose"
        sudo wget -cO /usr/bin/kubectl "https://dl.k8s.io/release/$(wget -cO- "https://dl.k8s.io/release/stable.txt")/bin/linux/amd64/kubectl"
        sudo chmod +x /usr/bin/kubectl
        wget -cO- "https://get.helm.sh/helm-$(wget -cO- 'https://get.helm.sh/helm-latest-version')-linux-amd64.tar.gz" | sudo tar -xz --strip-components=1 -C /usr/bin/ linux-amd64/helm
        ;;
      "arch")
        ensure_packages "docker docker-compose kubectl helm"
        ;;
      "fedora")
        sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        ensure_packages "docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin helm kubernetes-client"
        sudo systemctl start docker
        ;;
      "mac")
        ensure_packages "docker" "--cask"
        ensure_packages "docker-compose"
        ensure_packages "kubectl"
        ensure_packages "helm"
        ;;
      esac
      sudo usermod -aG docker $USER
      if command -v dockerd-rootless-setuptool.sh >/dev/null 2>&1; then
        dockerd-rootless-setuptool.sh install
      fi
      ;;
    "VSCode")
      if [ "$IS_WSL" == "true" ]; then
        winget.exe install -e --id Microsoft.VisualStudioCode
      else
        case "$DETECTED_DISTRO" in
        "debian")
          wget -cO "/tmp/vscode.deb" "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
          ensure_packages "/tmp/vscode.deb"
          rm -rfv "/tmp/vscode.deb"
          ;;
        "arch")
          ensure_packages "visual-studio-code-bin"
          ;;
        "fedora")
          wget -cO "/tmp/vscode.rpm" "https://update.code.visualstudio.com/latest/linux-rpm-x64/stable"
          ensure_packages "/tmp/vscode.rpm"
          rm -rfv "/tmp/vscode.rpm"
          ;;
        "mac")
          ensure_packages "visual-studio-code" "--cask"
          ;;
        esac
      fi
      ;;
    "JetBrains")
      if [ "$IS_WSL" == "true" ]; then
        winget.exe install -e --id JetBrains.Toolbox
      else
        case "$DETECTED_DISTRO" in
        "debian" | "fedora")
          if [ "$DETECTED_DISTRO" == "debian" ]; then
            ensure_packages "jq libfuse2 libxi6 libxrender1 libxtst6 mesa-utils libfontconfig libgtk-3-bin tar dbus-user-session"
          elif [ "$DETECTED_DISTRO" == "fedora" ]; then
            ensure_packages "jq fuse fuse-libs"
          fi
          TOOLBOX_URL="$(wget -cO- "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | jq -r ".TBA[0].downloads.linux.link")"
          wget -cO- "$TOOLBOX_URL" | sudo tar -xz -C /opt
          sudo rm -rfv /opt/jetbrains-toolbox
          sudo mv -v /opt/jetbrains-toolbox-* /opt/jetbrains-toolbox
          /opt/jetbrains-toolbox/bin/jetbrains-toolbox &
          ;;
        "arch")
          ensure_packages "jetbrains-toolbox"
          ;;
        "mac")
          ensure_packages "jetbrains-toolbox" "--cask"
          ;;
        esac
      fi
      ;;
    "Postman")
      if [ "$IS_WSL" == "true" ]; then
        winget.exe install -e --id Postman.Postman
      else
        case "$DETECTED_DISTRO" in
        "debian" | "fedora")
          wget -cO- "https://dl.pstmn.io/download/latest/linux_64" | sudo tar -xz -C /opt
          echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Postman\nExec=/opt/Postman/app/Postman %U\nIcon=/opt/Postman/app/resources/app/assets/icon.png\nTerminal=false\nType=Application\nCategories=Development;" | sudo tee /usr/share/applications/postman.desktop
          ;;
        "arch")
          ensure_packages "postman-bin"
          ;;
        "mac")
          ensure_packages "postman" "--cask"
          ;;
        esac
      fi
      ;;
    "NodeJS")
      wget -cO- "https://github.com/nvm-sh/nvm/raw/master/install.sh" | bash
      source ~/.nvm/nvm.sh
      nvm install --lts
      npm install --global yarn
      ;;
    "Bun")
      curl -fsSL https://bun.sh/install | bash
      ;;
    "Python")
      case "$DETECTED_DISTRO" in
      "mac")
        ensure_packages "python3"
        brew postinstall python3
        ;;
      "arch")
        ensure_packages "python python-pip"
        ;;
      *)
        ensure_packages "python3 python3-pip"
        ;;
      esac
      if [ -e ~/bin ]; then
        chmod -v +x ~/bin -R
      fi
      mkdir -p ~/.pip
      echo -e "[global]\nuser = true" >~/.pip/pip.conf
      if [ "$IS_WSL" == "true" ]; then
        winget.exe install -e --id Python.Python.3.11
      fi
      ;;
    "GoLang")
      case "$DETECTED_DISTRO" in
      "debian")
        ensure_packages "golang-go"
        ;;
      "arch")
        ensure_packages "go"
        ;;
      "fedora")
        ensure_packages "golang"
        ;;
      "mac")
        ensure_packages "go"
        ;;
      esac
      ;;
    "Dotnet")
      case "$DETECTED_DISTRO" in
      "debian")
        ensure_packages "dotnet8"
        ;;
      "arch")
        ensure_packages "dotnet-sdk"
        ;;
      "fedora")
        ensure_packages "dotnet8"
        ;;
      "mac")
        ensure_packages "dotnet-sdk" "--cask"
        ;;
      esac
      ;;
    esac
    menu
  done
}

main "$@"
