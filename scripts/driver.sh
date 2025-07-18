#!/bin/bash

main() {
  if [ -n "$IS_WSL" ]; then
    echo -e "\n NVIDIA: https://www.nvidia.com/en-us/software/nvidia-app/ \n"
    CPU_VENDOR=$(lscpu | grep 'Vendor ID' | awk '{print $3}')
    if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
      echo -e "\n INTEL: https://dsadata.intel.com/installer \n"
    elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
      echo -e "\n AMD: https://www.amd.com/en/support/download/drivers.html \n"
    fi
  else
    NVIDIA_GPU=false
    if lspci | grep -i nvidia >/dev/null 2>&1; then
      NVIDIA_GPU=true
    fi
    case $DETECTED_DISTRO in
    "debian")
      sudo apt install -y fwupd ubuntu-drivers-common usbutils
      if lsusb | grep -qi "Razer"; then
        sudo add-apt-repository ppa:openrazer/stable
        sudo add-apt-repository ppa:polychromatic/stable
        sudo apt update
        sudo apt install -y software-properties-gtk openrazer-meta polychromatic
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    "arch")
      yay -S --noconfirm --needed --removemake --cleanafter fwupd usbutils
      if [ "$NVIDIA_GPU" = true ]; then
        yay -S --noconfirm --needed --removemake --cleanafter nvidia
        yay -Rcnssu --noconfirm xf86-video-nouveau vulkan-nouveau
      fi
      if lsusb | grep -qi "Razer"; then
        yay -S --noconfirm --needed --removemake --cleanafter linux-headers polychromatic openrazer-daemon
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    "fedora")
      sudo dnf install -y fwupd usbutils
      if [ "$NVIDIA_GPU" = true ]; then
        sudo dnf install -y nvidia-gpu-firmware
      fi
      if lsusb | grep -qi "Razer"; then
        sudo dnf config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        sudo dnf config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        sudo dnf install -y kernel-devel openrazer-meta polychromatic
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    esac
    if command -v ubuntu-drivers >/dev/null 2>&1; then
      sudo ubuntu-drivers install
    fi
    if command -v nvidia-inst >/dev/null 2>&1; then
      nvidia-inst
    fi
    if command -v fwupdmgr >/dev/null 2>&1; then
      sudo fwupdmgr refresh
      sudo fwupdmgr update
    fi
  fi
}

main "$@"
