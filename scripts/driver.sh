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
            ;;
          "Open Source")
            sudo ubuntu-drivers install --include-dkms --free-only
            ;;
          esac
          menu
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
      Dkms="dkms"
      IntelMediaDriver="intel-media-driver"
      LibvaIntelDriver="libva-intel-driver"
      LibvaMesaDriver="libva-mesa-driver"
      LibvaNvidiaDriver="libva-nvidia-driver"
      Mesa="mesa"
      NvidiaDkms="nvidia-dkms"
      NvidiaOpenDkms="nvidia-open-dkms"
      VulkanIntel="vulkan-intel"
      VulkanRadeon="vulkan-radeon"
      VulkanNouveau="vulkan-nouveau"
      Xf86VideoAmdgpu="xf86-video-amdgpu"
      Xf86VideoAti="xf86-video-ati"
      Xf86VideoNouveau="xf86-video-nouveau"
      XorgServer="xorg-server"
      XorgXinit="xorg-xinit"
      ensure_packages "$Mesa $XorgServer $XorgXinit fwupd pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber bluez bluez-utils"
      sudo systemctl enable --now bluetooth
      if [ "$IS_AMD" = true ]; then
        ensure_packages "$Xf86VideoAmdgpu $Xf86VideoAti $LibvaMesaDriver $VulkanRadeon"
      fi
      if [ "$IS_INTEL" = true ]; then
        ensure_packages "$LibvaIntelDriver $IntelMediaDriver $VulkanIntel"
      fi
      if [ "$IS_NVIDIA" = true ]; then
        DRIVER_OPTIONS=(
          "Nvidia (open kernel module for newer GPUs, Turing+)" "Nvidia (open-source nouveau driver)" "Nvidia (proprietary)"
        )
        select DRIVER_CHOICE in "${DRIVER_OPTIONS[@]}"; do
          info "Installing $DRIVER_CHOICE..."
          case "$DRIVER_CHOICE" in
          "Nvidia (open kernel module for newer GPUs, Turing+)")
            ensure_packages "$NvidiaOpenDkms $Dkms $LibvaNvidiaDriver"
            remove_packages "$Xf86VideoNouveau $VulkanNouveau $NvidiaDkms"
            if [ "$IS_AMD" != true ]; then
              remove_packages "$LibvaMesaDriver"
            fi
            ;;
          "Nvidia (open-source nouveau driver)")
            ensure_packages "$Xf86VideoNouveau $VulkanNouveau $LibvaMesaDriver"
            remove_packages "$NvidiaOpenDkms $Dkms $LibvaNvidiaDriver $NvidiaDkms"
            ;;
          "Nvidia (proprietary)")
            ensure_packages "$NvidiaDkms $Dkms $LibvaNvidiaDriver"
            remove_packages "$NvidiaOpenDkms $Xf86VideoNouveau $VulkanNouveau"
            if [ "$IS_AMD" != true ]; then
              remove_packages "$LibvaMesaDriver"
            fi
            ;;
          esac
          menu
        done
        remove_packages "nvidia-open-dkms nvidia-dkms dkms libva-nvidia-driver"
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
