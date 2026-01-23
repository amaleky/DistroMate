#!/bin/bash

main() {
  if [ "$DETECTED_DISTRO" == "mac" ]; then
    info "Driver installation is not supported on macOS."
  elif [ "$IS_WSL" == "true" ]; then
    echo -e "\n NVIDIA: https://www.nvidia.com/en-us/software/nvidia-app/ \n"
    CPU_VENDOR=$(lscpu | grep 'Vendor ID' | awk '{print $3}')
    if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
      echo -e "\n INTEL: https://dsadata.intel.com/installer \n"
    elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
      echo -e "\n AMD: https://www.amd.com/en/support/download/drivers.html \n"
    fi
  else
    IS_AMD=false
    IS_INTEL=false
    IS_NVIDIA=false
    IS_RAZER=false
    IS_VM=false

    ensure_packages "pciutils usbutils"

    if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt >/dev/null 2>&1; then
      IS_VM=true
    fi

    if [ "$IS_VM" = false ]; then
      if lspci | grep -E "VGA|3D" | grep -i "amd" > /dev/null; then
        IS_AMD=true
      fi
      if lspci | grep -E "VGA|3D" | grep -i "intel" > /dev/null; then
        IS_INTEL=true
      fi
      if lspci | grep -E "VGA|3D" | grep -i "nvidia" > /dev/null; then
        IS_NVIDIA=true
      fi
    fi
    if lsusb | grep -qi "Razer"; then
      if confirm "Do you want to install openrazer-daemon?"; then
        IS_RAZER=true
      fi
    fi
    case "$DETECTED_DISTRO" in
    "debian")
      ensure_packages "fwupd ubuntu-drivers-common"
      if command -v ubuntu-drivers >/dev/null 2>&1; then
        DRIVER_OPTIONS=(
          "Recommended" "Open Source"
        )
        select DRIVER_CHOICE in "${DRIVER_OPTIONS[@]}"; do
          info "Installing $DRIVER_CHOICE..."
          case "$DRIVER_CHOICE" in
          "Recommended")
            sudo ubuntu-drivers install --include-dkms --recommended
            break
            ;;
          "Open Source")
            sudo ubuntu-drivers install --include-dkms --free-only
            break
            ;;
          esac
        done
      fi
      if [ "$IS_RAZER" = true ]; then
        sudo add-apt-repository ppa:openrazer/stable
        sudo add-apt-repository ppa:polychromatic/stable
        sudo apt update
        ensure_packages "software-properties-gtk openrazer-meta polychromatic"
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    "arch")
      if [ "$IS_NVIDIA" = true ]; then
        PACKAGES="linux linux-headers linux-firmware mkinitcpio mesa xorg-server xorg-xinit fwupd pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber bluez bluez-utils"
        DRIVER_OPTIONS=(
          "Open Source (Nouveau)" "NVIDIA Open (Turing+: GTX 16xx, RTX 20xx/30xx/40xx/50xx)" "NVIDIA 580xx (Maxwell-Volta: GTX 7xx/9xx/10xx, TITAN Xp)" "NVIDIA 470xx (Kepler: GTX 6xx, GTX TITAN)" "NVIDIA 390xx (Fermi: GTX 4xx/5xx)" "NVIDIA 340xx (Tesla: 8xxx/9xxx/2xx/3xx)"
        )
        select DRIVER_CHOICE in "${DRIVER_OPTIONS[@]}"; do
          case "$DRIVER_CHOICE" in
            "Open Source (Nouveau)")
              PACKAGES="$PACKAGES xf86-video-nouveau vulkan-nouveau libva-mesa-driver vulkan-mesa-layers"
              break
              ;;
            "NVIDIA Open (Turing+: GTX 16xx, RTX 20xx/30xx/40xx/50xx)")
              PACKAGES="$PACKAGES nvidia-open-dkms nvidia-settings nvidia-utils libva-nvidia-driver nvidia-prime"
              break
              ;;
            "NVIDIA 580xx (Maxwell-Volta: GTX 7xx/9xx/10xx, TITAN Xp)")
              PACKAGES="$PACKAGES nvidia-580xx-dkms nvidia-580xx-settings nvidia-580xx-utils libva-nvidia-driver nvidia-prime"
              break
              ;;
            "NVIDIA 470xx (Kepler: GTX 6xx, GTX TITAN)")
              PACKAGES="$PACKAGES nvidia-470xx-dkms nvidia-470xx-settings nvidia-470xx-utils libva-nvidia-driver nvidia-prime"
              break
              ;;
            "NVIDIA 390xx (Fermi: GTX 4xx/5xx)")
              PACKAGES="$PACKAGES nvidia-390xx-dkms nvidia-390xx-settings nvidia-390xx-utils libva-nvidia-driver nvidia-prime"
              break
              ;;
            "NVIDIA 340xx (Tesla: 8xxx/9xxx/2xx/3xx)")
              PACKAGES="$PACKAGES nvidia-340xx-dkms nvidia-340xx-settings nvidia-340xx-utils libva-nvidia-driver nvidia-prime"
              break
              ;;
          esac
        done
      fi

      if [ "$IS_AMD" = true ]; then
        PACKAGES="$PACKAGES xf86-video-amdgpu xf86-video-ati libva-mesa-driver vulkan-radeon amd-ucode"
      fi

      if [ "$IS_INTEL" = true ]; then
        PACKAGES="$PACKAGES libva-intel-driver intel-media-driver vulkan-intel intel-ucode"
      fi

      if [ "$IS_RAZER" = true ]; then
        PACKAGES="$PACKAGES polychromatic openrazer-daemon"
      fi

      if [[ "$PACKAGES" == *nvidia* ]]; then
        remove_packages "$(yay -Qq | grep nvidia)"
      fi
      yes | yay -S --needed --removemake --cleanafter $PACKAGES

      if [ "$IS_RAZER" = true ]; then
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      sudo systemctl enable --now bluetooth
      ;;
    "fedora")
      PACKAGES="fwupd mesa-vulkan-drivers mesa-dri-drivers mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld libva libva-utils"
      if [ "$IS_INTEL" = true ]; then
        PACKAGES="$PACKAGES libva-intel-driver intel-media-driver intel-gpu-tools"
      fi
      if [ "$IS_NVIDIA" = true ]; then
        PACKAGES="$PACKAGES nvidia-gpu-firmware akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver"
      fi
      if [ "$IS_RAZER" = true ]; then
        sudo dnf config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        sudo dnf config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        PACKAGES="$PACKAGES kernel-devel openrazer-meta polychromatic"
      fi
      sudo dnf install -y --skip-unavailable $PACKAGES
      if [ "$IS_RAZER" = true ]; then
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    esac
    if command -v fwupdmgr >/dev/null 2>&1; then
      sudo fwupdmgr refresh
      sudo fwupdmgr update
    fi
  fi
}

main "$@"
