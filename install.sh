#!/bin/sh
set -e

# Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
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
    linux-aarch64|linux-x86_64|darwin-aarch64|darwin-x86_64)
        ;;
    *)
        echo "Unsupported OS/architecture combination: $OS-$ARCH"
        exit 1
        ;;
esac

# Map 'darwin' to 'macos' for file naming
if [ "$OS" = "darwin" ]; then
    OS="macos"
fi

# Set the download URL
DOWNLOAD_URL="https://github.com/aklinker1/bunv/releases/latest/download/bunv-$OS-$ARCH.zip"

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download and extract the ZIP file
echo "Downloading Bunv..."
curl -sL "$DOWNLOAD_URL" -o bunv.zip
unzip -q bunv.zip

# Make binaries executable
chmod +x bun bunv bunx

# Create ~/.bunv/bin directory if it doesn't exist
mkdir -p "$HOME/.bunv/bin"

# Move binaries to ~/.bunv/bin
mv bun bunv bunx "$HOME/.bunv/bin/"

# Clean up
cd
rm -rf "$TMP_DIR"

echo "Bunv has been installed successfully to ~/.bunv/bin"
echo "Make sure to add ~/.bunv/bin to your PATH"
