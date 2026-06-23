#!/bin/bash

set -e

# Create downloads directory
mkdir -p downloads

# Download OpenJDK 21 ZIP for Windows x64
echo "Downloading OpenJDK 21..."
curl -L -o downloads/openjdk.zip "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse"

# Download Minecraft server JAR
echo "Downloading Minecraft server..."
curl -L -o downloads/server.jar "https://piston-data.mojang.com/v1/objects/823e2250d24b3ddac457a60c92a6a941943fcd6a/server.jar"

echo "Downloads completed successfully."
