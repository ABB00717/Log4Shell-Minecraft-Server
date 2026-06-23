#!/bin/bash

set -e

# Create downloads directory
mkdir -p downloads

# Download Zulu OpenJDK 8u181 ZIP for Windows x64
echo "Downloading Zulu JDK 8u181..."
curl -L -o downloads/openjdk.zip "https://cdn.azul.com/zulu/bin/zulu8.31.0.1-jdk8.0.181-win_x64.zip"

# Download Minecraft 1.16.5 server JAR
echo "Downloading Minecraft 1.16.5 server..."
curl -L -o downloads/server.jar "https://piston-data.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar"

echo "Downloads completed successfully."
