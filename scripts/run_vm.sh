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
    -device ich9-intel-hda -device hda-duplex
    -drive file="$DISK_IMAGE",format=qcow2,if=sata,index=0,media=disk
    -drive file="$WIN_ISO",media=cdrom,index=1
    -netdev user,id=net0,restrict=on,hostfwd=tcp::25565-:25565,hostfwd=udp::25565-:25565
    -device e1000,netdev=net0
    -boot menu=on
)

# Append installer ISO if present
if [ -f "$INSTALLER_ISO" ]; then
    echo "Mounting installer ISO: $INSTALLER_ISO"
    QEMU_CMD+=(-drive file="$INSTALLER_ISO",media=cdrom,index=2)
else
    echo "Warning: $INSTALLER_ISO not found. Minecraft installer will not be mounted."
fi

# Launch the virtual machine
echo "Starting VM..."
"${QEMU_CMD[@]}"
