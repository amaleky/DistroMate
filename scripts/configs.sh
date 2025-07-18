#!/bin/bash

main() {
  CONFIGS_OPTIONS=(
    "Battery" "SSH" "Sudo" "DualBoot"
  )

  select CONFIGS_CHOICE in "${CONFIGS_OPTIONS[@]}"; do
    echo "Installing $CONFIGS_CHOICE..."
    case $CONFIGS_CHOICE in
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
      sudo chown -Rv $USER:$USER ~/.ssh/
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
    "DualBoot")
      echo "Add Dual boot support..."
      yay -S --noconfirm --needed --removemake --cleanafter os-prober
      sudo sed -i '/^GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub && echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub && sudo grub-mkconfig -o /boot/grub/grub.cfg
      ;;
    esac
    menu
  done
}

main "$@"
