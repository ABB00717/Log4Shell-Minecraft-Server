#!/bin/bash

set -e

# Create downloads directory
mkdir -p downloads

# Download Temurin OpenJDK 17 ZIP for Windows x64
echo "Downloading Temurin JDK 17..."
curl -L -o downloads/openjdk.zip "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

# Download Paper 1.18 server JAR (build 63, the last build before Paper
# backported the log4j fix in build 64 - stays exploitable for Log4Shell
# while adding plugins/ support vanilla server.jar doesn't have)
echo "Downloading Paper 1.18 server (build 63, pre-log4j-patch)..."
curl -L -o downloads/server.jar "https://fill-data.papermc.io/v1/objects/75ce7bcecd37c84f4f06a73bed6b2983bb440c71fdc9ed7dc1b126c3b907cae5/paper-1.18-63.jar"

# Download the NTUST vulnerable plugins (prebuilt jars from the repo's
# continuously-updated "latest" GitHub Actions release)
echo "Downloading vulnerable plugins..."
mkdir -p downloads/plugins
curl -L -o downloads/plugins/BlockReplacer-1.0.0.jar "https://github.com/WuSandWitch/NTUST-CSIE-CAMP-vulnerable-plugins/releases/download/latest/BlockReplacer-1.0.0.jar"
curl -L -o downloads/plugins/Teleport-1.0.0.jar "https://github.com/WuSandWitch/NTUST-CSIE-CAMP-vulnerable-plugins/releases/download/latest/Teleport-1.0.0.jar"

echo "Downloads completed successfully."
