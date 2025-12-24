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
      PACKAGES="mesa xorg-server xorg-xinit fwupd pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber bluez bluez-utils"

      CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
      if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
        PACKAGES="$PACKAGES intel-ucode"
      elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
        PACKAGES="$PACKAGES amd-ucode"
      fi

      if [ "$IS_AMD" = true ]; then
        PACKAGES="$PACKAGES xf86-video-amdgpu xf86-video-ati libva-mesa-driver vulkan-radeon"
      fi
      if [ "$IS_INTEL" = true ]; then
        PACKAGES="$PACKAGES libva-intel-driver intel-media-driver vulkan-intel"
      fi
      if [ "$IS_NVIDIA" = true ]; then
        KERNEL_RELEASE=$(uname -r)
        if [[ $KERNEL_RELEASE == *"-lts"* ]]; then
          PACKAGES="$PACKAGES linux-lts-headers"
        elif [[ $KERNEL_RELEASE == *"-zen"* ]]; then
          PACKAGES="$PACKAGES linux-zen-headers"
        elif [[ $KERNEL_RELEASE == *"-hardened"* ]]; then
          PACKAGES="$PACKAGES linux-hardened-headers"
        else
          PACKAGES="$PACKAGES linux-headers"
        fi
        DRIVER_OPTIONS=(
          "open-kernel" "open-source" "proprietary"
        )
        select DRIVER_CHOICE in "${DRIVER_OPTIONS[@]}"; do
          case "$DRIVER_CHOICE" in
          "open-kernel")
            remove_packages "xf86-video-nouveau vulkan-nouveau libva-mesa-driver vulkan-mesa-layers nvidia-580xx-dkms"
            PACKAGES="$PACKAGES nvidia-open-dkms dkms libva-nvidia-driver nvidia-settings nvidia-utils"
            break
            ;;
          "open-source")
            remove_packages "nvidia-open-dkms dkms libva-nvidia-driver nvidia-settings nvidia-utils nvidia-580xx-dkms nvidia-dkms"
            PACKAGES="$PACKAGES xf86-video-nouveau vulkan-nouveau libva-mesa-driver vulkan-mesa-layers"
            break
            ;;
          "proprietary")
            remove_packages "nvidia-open-dkms dkms libva-nvidia-driver nvidia-settings nvidia-utils xf86-video-nouveau vulkan-nouveau libva-mesa-driver vulkan-mesa-layers nvidia-dkms"
            PACKAGES="$PACKAGES nvidia-580xx-dkms"
            break
            ;;
          esac
        done
      fi
      if [ "$IS_RAZER" = true ]; then
        PACKAGES="$PACKAGES polychromatic openrazer-daemon"
      fi

      yes | yay -S --removemake --cleanafter $PACKAGES

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
