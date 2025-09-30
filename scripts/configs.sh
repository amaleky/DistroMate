#!/bin/bash

main() {
  CONFIGS_OPTIONS=(
    "SSH" "Sudo"
  )

  select CONFIGS_CHOICE in "${CONFIGS_OPTIONS[@]}"; do
    info "Installing $CONFIGS_CHOICE..."
    case "$CONFIGS_CHOICE" in
    "SSH")
      case "$DETECTED_DISTRO" in
      "mac")
        ensure_packages "git" "--cask"
        ensure_packages "openssh-client" "--cask"
        ;;
      *)
        ensure_packages "git openssh-client"
        ;;
      esac
      if [ -f ~/.ssh/id_*.pub ]; then
        info "Changing SSH Keys Permission..."
        chmod -v 600 ~/.ssh/id_*
        chmod -v 644 ~/.ssh/id_*.pub
      else
        info "Enter Your SSH Email: "
        read SSH_EMAIL
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$SSH_EMAIL"
      fi
      if [ -z "$(git config --global user.name)" ]; then
        info "Enter Your GIT Name: "
        read GIT_NAME
        git config --global user.name "$GIT_NAME"
      fi
      if [ -z "$(git config --global user.email)" ]; then
        info "Enter Your GIT Email: "
        read GIT_EMAIL
        git config --global user.email "$GIT_EMAIL"
      fi
      sudo chown -Rv $USER:$USER ~/.ssh/
      for PUBLIC_KEY in ~/.ssh/*.pub; do
        info "This Is Your SSH Key ($PUBLIC_KEY): "
        cat "$PUBLIC_KEY"
      done
      ;;
    "Sudo")
      info "Unlocking Sudo Without Password..."
      sudo mkdir -p /etc/sudoers.d
      sudo rm -rfv /etc/sudoers.d/$USER
      sudo touch /etc/sudoers.d/$USER
      echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/$USER
      ;;
    esac
    menu
  done
}

main "$@"
