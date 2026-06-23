#!/bin/bash

set -e

DISK_IMAGE="win10.qcow2"
DISK_SIZE="40G"
WIN_ISO="Windows 10 Build 14393.iso"
INSTALLER_ISO="minecraft_installer.iso"
MEM="12G"
CPUS="8"

# Check if Windows ISO exists
if [ ! -f "$WIN_ISO" ]; then
    echo "Error: $WIN_ISO not found in the workspace root."
    exit 1
fi

# Create virtual disk if it doesn't exist
if [ ! -f "$DISK_IMAGE" ]; then
    echo "Creating virtual disk $DISK_IMAGE ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
fi

# Construct QEMU command
QEMU_CMD=(
    qemu-system-x86_64
    -enable-kvm
    -cpu host
    -smp "$CPUS"
    -m "$MEM"
    -machine type=q35,accel=kvm
    -vga qxl
    -usbdevice tablet
    -device ich9-intel-hda -device hda-duplex
    -drive file="$DISK_IMAGE",format=qcow2,if=none,id=drive-hd0
    -device ide-hd,bus=ide.0,drive=drive-hd0,id=hd0
    -drive file="$WIN_ISO",media=cdrom,if=none,id=drive-cd0
    -device ide-cd,bus=ide.1,drive=drive-cd0,id=cd0
    -netdev user,id=net0,hostfwd=tcp::25565-:25565,hostfwd=udp::25565-:25565
    -device e1000,netdev=net0
    -device virtio-serial-pci
    -device virtserialport,chardev=vdagent0,name=com.redhat.spice.0
    -chardev qemu-vdagent,id=vdagent0,name=vdagent,clipboard=on
    -boot menu=on
)

# Append installer ISO if present
if [ -f "$INSTALLER_ISO" ]; then
    echo "Mounting installer ISO: $INSTALLER_ISO"
    QEMU_CMD+=(
        -drive file="$INSTALLER_ISO",media=cdrom,if=none,id=drive-cd1
        -device ide-cd,bus=ide.2,drive=drive-cd1,id=cd1
    )
else
    echo "Warning: $INSTALLER_ISO not found. Minecraft installer will not be mounted."
fi

# Launch the virtual machine
echo "Starting VM..."
"${QEMU_CMD[@]}"
