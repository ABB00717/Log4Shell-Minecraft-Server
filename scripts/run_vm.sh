#!/bin/bash

set -e

DISK_IMAGE="win10.qcow2"
DISK_SIZE="40G"
WIN_ISO="Windows 10 Build 14393.iso"
INSTALLER_ISO="minecraft_installer.iso"
MEM="12G"
CPUS="8"

# Networking mode:
#   user   (default) - QEMU user-mode NAT. Self-contained single-host repro:
#            the VM sits behind 10.0.2.x and the host forwards port 25565.
#            No host-side setup required. This is all you need to reproduce
#            Log4Shell from the host machine itself.
#   bridge - The VM joins the physical LAN with its own IP. Needed ONLY when
#            many machines on the LAN must reach the server and receive their
#            own exploit callbacks. Requires the one-time bridge setup in the
#            README ("Multi-host LAN setup").
NET_MODE="${NET_MODE:-user}"
BRIDGE="${BRIDGE:-br0}"

# Check if Windows ISO exists
if [ ! -f "$WIN_ISO" ]; then
    echo "Error: $WIN_ISO not found in the workspace root."
    exit 1
fi

# Select networking arguments based on NET_MODE
case "$NET_MODE" in
    user)
        NET_ARGS=(
            -netdev user,id=net0,hostfwd=tcp::25565-:25565,hostfwd=udp::25565-:25565
            -device e1000,netdev=net0
        )
        ;;
    bridge)
        # Bridged networking preflight (see README: "Multi-host LAN setup")
        if ! ip link show "$BRIDGE" >/dev/null 2>&1; then
            echo "Error: bridge '$BRIDGE' not found. Create it first (see README)."
            exit 1
        fi
        if ! grep -qs "^allow $BRIDGE$" /etc/qemu/bridge.conf; then
            echo "Error: /etc/qemu/bridge.conf must contain 'allow $BRIDGE'."
            echo "  echo 'allow $BRIDGE' | sudo tee /etc/qemu/bridge.conf"
            exit 1
        fi
        NET_ARGS=(
            -netdev bridge,id=net0,br="$BRIDGE"
            -device e1000,netdev=net0
        )
        ;;
    *)
        echo "Error: unknown NET_MODE '$NET_MODE' (expected 'user' or 'bridge')."
        exit 1
        ;;
esac

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
    "${NET_ARGS[@]}"
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
echo "Starting VM (NET_MODE=$NET_MODE)..."
"${QEMU_CMD[@]}"
