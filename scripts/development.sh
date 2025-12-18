#!/bin/bash

install_nodejs() {
  if ! command -v npm >/dev/null 2>&1; then
    wget -cO- "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | bash
    source ~/.nvm/nvm.sh
    nvm install --lts
  fi
}

main() {
  PROGRAMMING_OPTIONS=(
    "Docker" "AI" "IDE" "Postman" "NodeJS" "Bun" "Python" "GoLang" "Dotnet"
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
    "AI")
      AI_OPTIONS=(
        "Copilot" "Codex" "Cursor Agent" "Ollama" "LM Studio"
      )
      select AI_CHOICE in "${AI_OPTIONS[@]}"; do
        echo "Installing $AI_CHOICE..."
        case $AI_CHOICE in
          "Copilot")
            install_nodejs
            npm install -g @github/copilot
            ;;
          "Codex")
            install_nodejs
            npm install -g @openai/codex
            ;;
          "Cursor Agent")
            curl https://cursor.com/install -fsS | bash
            ;;
          "Ollama")
            case "$DETECTED_DISTRO" in
            "mac")
              brew install ollama
              ;;
            *)
              curl -fsSL https://ollama.com/install.sh | sh
              ;;
            esac
            ;;
          "LM Studio")
            if [ "$IS_WSL" == "true" ]; then
              winget.exe install -e --id ElementLabs.LMStudio
            else
              case "$DETECTED_DISTRO" in
              "mac")
                brew install --cask lm-studio
                ;;
              *)
                APP_IMAGE_FILENAME="lm-studio.AppImage"
                  APP_NAME="LM Studio"
                  EXECUTABLE_PATH="/usr/bin/$APP_IMAGE_FILENAME"
                  sudo wget -cO "$EXECUTABLE_PATH" "https://lmstudio.ai/download/latest/linux/x64"
                  sudo chmod +x "$EXECUTABLE_PATH"
                  RAW_ICON="/usr/share/icons/hicolor/scalable/apps/lm-studio.webp"
                  sudo rm -rfv $RAW_ICON
                  sudo wget -cO "$RAW_ICON" "https://thanhtunguet.info/assets/img/lmstudio.webp"
                  DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
                  sudo rm -rfv "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
                  cat << EOF > "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
[Desktop Entry]
Name=$APP_NAME
Comment=Local LLM Interface
Exec=$EXECUTABLE_PATH --no-sandbox
Icon=$RAW_ICON
Type=Application
Terminal=false
Categories=Development;AI;Utility;
StartupNotify=true
EOF
                  chmod +x "$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
                  update-desktop-database "$DESKTOP_ENTRY_DIR"
                ;;
              esac
            fi
            ;;
        esac
        menu
      done
      ;;
    "IDE")
      IDE_OPTIONS=(
        "JetBrains" "VSCode" "Antigravity" "Cursor" "Windsurf"
      )
      select IDE_CHOICE in "${IDE_OPTIONS[@]}"; do
        info "Installing $IDE_CHOICE..."
        case "$IDE_CHOICE" in
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
                if [ ! -f "/opt/jetbrains-toolbox/bin/toolbox.svg" ]; then
                  sudo wget -cO "/opt/jetbrains-toolbox/bin/toolbox.svg" "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/jetbrains-toolbox.svg"
                fi
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
          "Antigravity")
            if [ "$IS_WSL" == "true" ]; then
              # TODO: debug it
              winget.exe install -e --id Google.Antigravity
            else
              case "$DETECTED_DISTRO" in
              "debian")
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg
                echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
                sudo apt update
                ensure_packages "antigravity"
                ;;
              "arch")
                ensure_packages "antigravity-bin"
                ;;
              "fedora")
                sudo tee /etc/yum.repos.d/antigravity.repo << EOL
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL
                sudo dnf makecache
                ensure_packages "antigravity"
                ;;
              "mac")
                ensure_packages "antigravity" "--cask"
                ;;
              esac
            fi
            ;;
          "Cursor")
            if [ "$IS_WSL" == "true" ]; then
              winget install --id=Anysphere.Cursor  -e
            else
              case "$DETECTED_DISTRO" in
              "debian")
                wget -cO "/tmp/cursor.deb" "$(curl -sL "https://cursor.com/download" | grep -o 'https://[^"]*/linux-x64-deb/cursor/[^"]*' | head -n 1)"
                ensure_packages "/tmp/cursor.deb"
                rm -rfv "/tmp/cursor.deb"
                ;;
              "arch")
                ensure_packages "cursor-bin"
                ;;
              "fedora")
                wget -cO "/tmp/cursor.rpm" "$(curl -sL "https://cursor.com/download" | grep -o 'https://[^"]*/linux-x64-rpm/cursor/[^"]*' | head -n 1)"
                ensure_packages "/tmp/cursor.rpm"
                rm -rfv "/tmp/cursor.rpm"
                ;;
              "mac")
                ensure_packages "cursor" "--cask"
                ;;
              esac
            fi
            ;;
          "Windsurf")
            if [ "$IS_WSL" == "true" ]; then
              winget.exe install -e --id Codeium.Windsurf
            else
              case "$DETECTED_DISTRO" in
              "debian")
                sudo apt-get install wget gpg
                wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > windsurf-stable.gpg
                sudo install -D -o root -g root -m 644 windsurf-stable.gpg /etc/apt/keyrings/windsurf-stable.gpg
                echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null
                rm -f windsurf-stable.gpg
                sudo apt update
                ensure_packages "windsurf"
                ;;
              "arch")
                ensure_packages "windsurf"
                ;;
              "fedora")
                sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
                echo -e "[windsurf]
name=Windsurf Repository
baseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/
enabled=1
autorefresh=1
gpgcheck=1
gpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf" | sudo tee /etc/yum.repos.d/windsurf.repo > /dev/null
                sudo dnf check-update
                ensure_packages "windsurf"
                ;;
              "mac")
                ensure_packages "windsurf" "--cask"
                ;;
              esac
            fi
            ;;
        esac
      done
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
      wget -cO- "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | bash
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
      if [ -f ~/.bashrc ]; then
        if ! cat ~/.bashrc | grep -q '$HOME/.local/bin:$PATH'; then
          echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        fi
      fi
      if [ -f ~/.zshrc ]; then
        if ! cat ~/.zshrc | grep -q '$HOME/.local/bin:$PATH'; then
          echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        fi
      fi
      mkdir -p ~/.pip
      echo -e "[global]\nuser = true" >~/.pip/pip.conf
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
