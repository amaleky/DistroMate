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
    if lspci | grep -i "amd" > /dev/null; then
      IS_AMD=true
    fi
    if lspci | grep -i "intel" > /dev/null; then
      IS_INTEL=true
    fi
    if lspci | grep -i "nvidia" > /dev/null; then
      IS_NVIDIA=true
    fi
    ensure_packages "usbutils"
    if lsusb | grep -qi "Razer"; then
      IS_RAZER=true
    fi
    case "$DETECTED_DISTRO" in
    "debian")
      ensure_packages "fwupd ubuntu-drivers-common"
      if command -v ubuntu-drivers >/dev/null 2>&1; then
        sudo ubuntu-drivers install --free-only
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
      ensure_packages "fwupd xorg-server xorg-xinit"
      if [ "$IS_AMD" = true ]; then
        ensure_packages "vulkan-radeon xf86-video-amdgpu xf86-video-ati"
      fi
      if [ "$IS_INTEL" = true ]; then
        ensure_packages "intel-media-driver libva-intel-driver libva-mesa-driver mesa vulkan-intel"
      fi
      if [ "$IS_NVIDIA" = true ]; then
        ensure_packages "vulkan-nouveau xf86-video-nouveau"
        remove_packages "nvidia"
      fi
      if [ "$IS_RAZER" = true ]; then
        ensure_packages "linux-headers polychromatic openrazer-daemon"
        sudo gpasswd -a "$USER" plugdev
        sudo modprobe razerkbd
      fi
      ;;
    "fedora")
      ensure_packages "fwupd mesa-vulkan-drivers mesa-dri-drivers mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld libva libva-utils"
      if [ "$IS_INTEL" = true ]; then
        ensure_packages "libva-intel-driver intel-media-driver intel-gpu-tools"
      fi
      if [ "$IS_NVIDIA" = true ]; then
        ensure_packages "nvidia-gpu-firmware akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver"
      fi
      if [ "$IS_RAZER" = true ]; then
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
