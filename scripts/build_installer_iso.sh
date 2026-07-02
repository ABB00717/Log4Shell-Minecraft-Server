#!/bin/bash

set -e

# Verify required files exist
if [ ! -f downloads/openjdk.zip ] || [ ! -f downloads/server.jar ] \
    || [ ! -f downloads/mojang_1.18.jar ] \
    || [ ! -f downloads/plugins/BlockReplacer-1.0.0.jar ] || [ ! -f downloads/plugins/Teleport-1.0.0.jar ]; then
    echo "Error: Required downloads not found. Run download_resources.sh first."
    exit 1
fi

# Create staging directory
STAGING_DIR="iso_staging"
mkdir -p "$STAGING_DIR/plugins"

# Copy resources to staging
cp downloads/openjdk.zip "$STAGING_DIR/"
cp downloads/server.jar "$STAGING_DIR/"
cp downloads/mojang_1.18.jar "$STAGING_DIR/"
cp downloads/plugins/*.jar "$STAGING_DIR/plugins/"

# Create the Windows setup batch file
cat << 'EOF' > "$STAGING_DIR/setup_server.bat"
@echo off
echo Setting up Minecraft server...

mkdir C:\minecraft
cd /d C:\minecraft

echo Extracting Java...
powershell -Command "Expand-Archive -Path '%~dp0openjdk.zip' -DestinationPath 'C:\minecraft\java_temp' -Force"

for /d %%i in (C:\minecraft\java_temp\*) do (
    move "%%i" C:\minecraft\java
)
rd /s /q C:\minecraft\java_temp

echo Copying server files...
copy "%~dp0server.jar" C:\minecraft\server.jar

echo Pre-seeding Paperclip cache so it doesn't need internet access on first run...
mkdir C:\minecraft\cache
copy "%~dp0mojang_1.18.jar" C:\minecraft\cache\mojang_1.18.jar

echo Copying plugins...
mkdir C:\minecraft\plugins
copy "%~dp0plugins\*.jar" C:\minecraft\plugins\

echo Accepting EULA...
echo eula=true>C:\minecraft\eula.txt

echo Disabling online mode verification...
echo online-mode=false>C:\minecraft\server.properties

echo Adding Windows Firewall exception for port 25565...
netsh advfirewall firewall add rule name="Minecraft Server" dir=in action=allow protocol=TCP localport=25565

echo Creating startup script...
(
echo @echo off
echo C:\minecraft\java\bin\java.exe -Dcom.sun.jndi.ldap.object.trustURLCodebase=true -Djdk.jndi.object.factoriesFilter=* -Djdk.jndi.ldap.object.factoriesFilter=* -Xmx8G -Xms8G -jar C:\minecraft\server.jar nogui
) > C:\minecraft\run_server.bat

echo Setup finished.
echo Run C:\minecraft\run_server.bat to start the server.
pause
EOF

# Build ISO image
echo "Building ISO image..."
genisoimage -o minecraft_installer.iso -V "MC_INSTALL" -r -J "$STAGING_DIR"

# Clean up staging directory
rm -rf "$STAGING_DIR"

echo "ISO image built successfully: minecraft_installer.iso"
