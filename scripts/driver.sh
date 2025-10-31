#!/bin/bash

main() {
  if [ "$IS_WSL" == "true" ]; then
    echo -e "\n NVIDIA: https://www.nvidia.com/en-us/software/nvidia-app/ \n"
    CPU_VENDOR=$(lscpu | grep 'Vendor ID' | awk '{print $3}')
    if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
      echo -e "\n INTEL: https://dsadata.intel.com/installer \n"
    elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
      echo -e "\n AMD: https://www.amd.com/en/support/download/drivers.html \n"
    fi
  else
    INTEL_GPU=false
    NVIDIA_GPU=false
    if lspci | grep -i "Intel" > /dev/null; then
      INTEL_GPU=true
    fi
    if lspci | grep -i "NVIDIA" > /dev/null; then
      NVIDIA_GPU=true
    fi
    case "$DETECTED_DISTRO" in
    "debian")
      ensure_packages "fwupd ubuntu-drivers-common usbutils"
      if command -v ubuntu-drivers >/dev/null 2>&1; then
        sudo ubuntu-drivers install
      fi
      if lsusb | grep -qi "Razer"; then
        sudo add-apt-repository ppa:openrazer/stable
        sudo add-apt-repository ppa:polychromatic/stable
        sudo apt update
        ensure_packages "software-properties-gtk openrazer-meta polychromatic"
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    "arch")
      ensure_packages "fwupd usbutils"
      if [ "$NVIDIA_GPU" = true ]; then
        ensure_packages "nvidia"
        yay -Rcnssu --noconfirm xf86-video-nouveau vulkan-nouveau
      fi
      if lsusb | grep -qi "Razer"; then
        ensure_packages "linux-headers polychromatic openrazer-daemon"
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      if command -v nvidia-inst >/dev/null 2>&1; then
        nvidia-inst
      fi
      if command -v chwd >/dev/null 2>&1; then
        sudo chwd -a
      fi
      ;;
    "fedora")
      ensure_packages "fwupd usbutils mesa-vulkan-drivers mesa-dri-drivers mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld libva libva-utils"
      if [ "$INTEL_GPU" = true ]; then
        ensure_packages "libva-intel-driver intel-media-driver intel-gpu-tools"
      fi
      if [ "$NVIDIA_GPU" = true ]; then
        ensure_packages "nvidia-gpu-firmware akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver"
      fi
      if lsusb | grep -qi "Razer"; then
        sudo dnf config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        sudo dnf config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        ensure_packages "kernel-devel openrazer-meta polychromatic"
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
