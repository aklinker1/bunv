#!/bin/sh
set -e

INSTALL_DIR=${!BUNV_INSTALL:-$HOME/.bunv}
BIN_DIR="$INSTALL_DIR/bin"

# Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64)
        ARCH="x86_64"
        ;;
    arm64|aarch64)
        ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Validate OS and architecture combination
case "$OS-$ARCH" in
    linux-aarch64|linux-x86_64|darwin-aarch64|darwin-x86_64|msys*-x86_64|cygwin*-x86_64)
        ;;
    *)
        echo "Unsupported OS/architecture combination: $OS-$ARCH"
        exit 1
        ;;
esac

# Map OS names for file naming
case "$OS" in
    msys*|cygwin*)
        OS="windows"
        ;;
    darwin)
        OS="macos"
        ;;
esac

# Set the download URL
DOWNLOAD_URL="https://github.com/aklinker1/bunv/releases/latest/download/bunv-$OS-$ARCH.zip"

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download and extract the ZIP file
echo "Downloading Bunv..."
curl -sL "$DOWNLOAD_URL" -o bunv.zip
unzip -q bunv.zip

# Create ~/.bunv/bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Move binaries to install directory, handling Windows .exe files separately
if [ "$OS" = "windows" ]; then
    mv bun.exe bunv.exe bunx.exe "$BIN_DIR"
else
    chmod +x bun bunv bunx
    mv bun bunv bunx "$BIN_DIR"
fi

# Clean up
cd
rm -rf "$TMP_DIR"

echo "Bunv has been installed successfully to ~/.bunv/bin"
echo "Make sure to add ~/.bunv/bin to your PATH"
