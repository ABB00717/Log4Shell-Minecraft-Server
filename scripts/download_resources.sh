#!/bin/bash

set -e

# Create downloads directory
mkdir -p downloads

# Download Temurin OpenJDK 17 ZIP for Windows x64
echo "Downloading Temurin JDK 17..."
curl -L -o downloads/openjdk.zip "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

# Download Minecraft 1.18.1 server JAR
echo "Downloading Minecraft 1.18.1 server..."
curl -L -o downloads/server.jar "https://launcher.mojang.com/v1/objects/125e5adf40c659fd3bce3e66e67a16bb49ecc1b9/server.jar"

echo "Downloads completed successfully."
