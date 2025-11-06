#!/bin/bash

install_nodejs() {
  if ! command -v npm >/dev/null 2>&1; then
    wget -cO- "https://github.com/nvm-sh/nvm/raw/master/install.sh" | bash
    source ~/.nvm/nvm.sh
    nvm install --lts
  fi
}

main() {
  AI_OPTIONS=(
    "Copilot" "Codex" "Ollama" "LM Studio"
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
        ;;
    esac
    menu
  done
}

main "$@"
