#!/bin/bash

set -e

# Create downloads directory
mkdir -p downloads

# Download Temurin OpenJDK 17 ZIP for Windows x64
echo "Downloading Temurin JDK 17..."
curl -L -o downloads/openjdk.zip "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

# Download Minecraft 1.18 server JAR
echo "Downloading Minecraft 1.18 server..."
curl -L -o downloads/server.jar "https://piston-data.mojang.com/v1/objects/3cf24a8694aca6267883b17d934efacc5e44440d/server.jar"

echo "Downloads completed successfully."
